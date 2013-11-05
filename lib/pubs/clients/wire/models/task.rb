require 'active_support/inflector'
require 'oj'

class Task < ActiveRecord::Base

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
  def queue action, context

    unless self.actions[action].is_a?(Array)
      self.errors.add :actions, "action[#{action}] is not an Array"
      return false
    end

    self.actions[action].each_with_index { |job, index|

      params = job.values.first
      klass = job.keys.first
      queue_name = "#{self.key}_#{action}_#{klass}_#{index}_#{context["id"]}"

      unless job = Delayed::Job.find_by(queue: queue_name)
        job = Delayed::Job.enqueue(
        # create Job with contextual object, action and parameters
        "Jobs::#{klass.classify}".constantize.new(context, params),
        # name the queue with tasks key
        queue: queue_name,
        # set priority or default is top!
        priority: params["priority"] || 0,
        # schedule if exists or run immediately
        run_at: eval(params.try(:[],"schedule") || "Time.now")
        )
        ap "ENQUED #{job.inspect}"
      end

      job

    }
  end

  private

  def normalize_key
    self.key  = self.key.parameterize.underscore
  end

end
