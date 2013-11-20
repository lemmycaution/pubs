require 'active_support/inflector'
require 'oj'
require 'delayed_job'

class Task < ActiveRecord::Base

  IMMEDIATELY = "immediately"

  validates_presence_of :key,:actions
  validates_uniqueness_of :key
  before_save :normalize_key

  # has_many :jobs, class_name: "::Delayed::Job",
  # foreign_key: "queue", primary_key: "key"

  attr_accessor :code

  serialize :actions, YAML

  def code
    self.dup.to_json(except: [:id,:key,:created_at,:updated_at])
  end

  def rep
    as_json(only: [:id,:name,:key,:created_at,:updated_at],methods:[:code])
  end

  # enqueue all tasks
  def queue action, job_id, context

    unless self.actions[action].is_a?(Array)
      self.errors.add :actions, "action[#{action}] is not an Array"
      return false
    end

    results = []
    self.actions[action].each_with_index { |job, index|

      params = job.values.first
      klass = job.keys.first
      queue_name = "#{self.key}_#{action}_#{klass}_#{index}_#{job_id}"



      unless job = Delayed::Job.find_by(queue: queue_name)

        handler = "Jobs::#{klass.classify}".constantize.new(context, params)
        schedule = params.try(:[],"schedule")

        job = Delayed::Job.enqueue(
        # create Job with contextual object, action and parameters
        handler,
        # name the queue with tasks key
        queue: queue_name,
        # set priority or default is top!
        priority: params["priority"] || 0,
        # schedule if exists or run immediately
        run_at: eval(schedule || "Time.now")
        )

        if schedule == IMMEDIATELY
           job.update!(locked_by: "immediate_worker",locked_at: Time.now)

          begin
            handler.before(job)
            handler.perform
            results << handler.result
            handler.success(job)
          rescue Exception => e
            handler.error(job, e)
            puts "ERROR --> #{e.inspect}"
          ensure
            handler.after(job)
          end

          job.destroy

        else
          results << job

        end

      end

    }

    results
  end

  private

  # throw it to future avoid duplicate runs
  def immediately
    Time.now
  end

  def normalize_key
    self.key  = self.key.parameterize.underscore
  end

end
