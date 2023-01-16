# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'active_support/inflector'

# require your gems as usual
Bundler.require(:default)

# UpdatedMandate.new
#   .has(:mandate, apply: { find_by_id: 1 })
#   .has(:active_front, apply: { active_front: 1 })

Something = Struct.new('Something', :foo, :bar)
Foo = Struct.new('Foo', :attr1)
Bar = Struct.new('Bar', :attr2)
foo = Foo.new(attr1: String.new('A string'))
bar = Bar.new(attr2: { a: :hash })
something = Something.new(foo:, bar:)

class DeclarativeService
  def initialize
    @failed = false
  end

  def has(trait_name)
    self.trait = trait_name

    self
  end

  def apply(trait_name, **kwargs)
    kwargs.each do |k, v|
      send(trait_name).send(k, v)
    end

    self
  end

  def failure!(message)
    raise StandardError, message
  end

  private

  def trait=(trait_name)
    instance_variable_set(:"@#{trait_name}", trait_class(trait_name).new(self))

    define_singleton_method(trait_name) do
      instance_variable_get(:"@#{trait_name}")
    end
  end

  def trait_class(trait)
    "#{self.class}/#{trait}".classify.constantize
  end

  class Trait
    def initialize(service)
      @service = service
    end

    def inspect
      @value
    end

    def method_missing(*)
      @value.send(*)
    end

    def respond_to_missing?(sym, *)
      @value.respond_to?(sym)
    end
  end
end

class UpdatedThing < DeclarativeService
  class Something < DeclarativeService::Trait
    def initialize(...)
      super
      @value = nil
    end

    def set(obj)
      @value = obj
    end

    def update_foo_string(string)
      @value.foo.attr1 = String.new(string)
    end
  end

  class Foo < DeclarativeService::Trait
    def initialize(...)
      super
      @value = @service.something.foo
    end

    def append(string)
      @value.attr1.concat " #{string}"
    rescue FrozenError => e
      @service.failure! e.message
    end
  end

  class Bar < DeclarativeService::Trait
    def initialize(...)
      super
      @value = @service.something.bar
    end

    def update_a(new_value)
      @value.attr2[:a] = new_value
    end
  end
end

o = UpdatedThing.new
                .has(:something).apply(:something, set: something, update_foo_string: 'Updated string')
                .has(:foo).apply(:foo, append: 'appended string')
                .has(:bar).apply(:bar, update_a: :new_value)
                .has(:foo).apply(:foo, append: 'another appended string')

binding.irb
