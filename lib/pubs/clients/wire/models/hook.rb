require 'active_support/inflector'
require 'oj'

class Hook < ActiveRecord::Base

  validates_presence_of :key,:actions
  validates_uniqueness_of :key
  before_save :normalize_key

  has_many :jobs, class_name: "Delayed::Job",
  primary_key: "queue", foreign_key: "key"

  attr_accessor :code

  serialize :actions, YAML

  def code
    self.dup.to_json(except: [:id,:key,:created_at,:updated_at])
  end

  def rep
    as_json(only: [:id,:name,:key,:created_at,:updated_at],methods:[:code])
  end

  # enqueue all tasks
  def queue callback, unit

    return { error: "action[#{callback}] is not an Array" } unless self.actions[callback].is_a?(Array)

    self.actions[callback].each { |job|

      params = job.values.first
      klass = job.keys.first

      Delayed::Job.enqueue(
      # create Job with contextual unit, method and parameters
      "Jobs::#{klass.classify}".constantize.new( unit, params),
      # name the queue with hooks key
      queue: self.key,
      # set priority or default is top!
      priority: params["priority"] || 0,
      # schedule if exists or run immediately
      run_at: eval(params.try(:[],"schedule") || "Time.now")
      )

    }
  end

  private

  def normalize_key
    self.key  = self.key.parameterize.underscore
  end

end
