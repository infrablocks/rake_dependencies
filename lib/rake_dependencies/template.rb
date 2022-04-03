# frozen_string_literal: true

require 'hamster'
require 'erb'

module RakeDependencies
  class Template
    def initialize(
      template,
      parameters = {}
    )
      @template = template
      @parameters = Hamster::Hash.new(parameters)
    end

    def with_parameter(key, value)
      Template.new(@template, @parameters.put(key, value))
    end

    def with_parameters(pairs)
      pairs.to_a.reduce(self) do |memo, parameter|
        memo.with_parameter(*parameter)
      end
    end

    def render
      context = Object.new
      @parameters.each do |key, value|
        context.instance_variable_set("@#{key}", value)
      end
      context_binding = context.instance_eval { binding }
      ERB.new(@template).result(context_binding)
    end
  end
end
