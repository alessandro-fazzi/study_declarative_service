# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'active_support/inflector'

# require your gems as usual
Bundler.require(:default)

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
    @failed = true
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
    attr_accessor :value

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

class NewlyAddedComment < DeclarativeService
  class Comment < DeclarativeService::Trait
    def post=(post)
      @value.post = post
    end

    def user=(user)
      @value.user = user
    end
  end

  class Post < DeclarativeService::Trait; end

  class User < DeclarativeService::Trait
    def initialize(...)
      super
      @value = @service.comment.user
    end

    def new_name(new_name) = self.name = new_name
  end
end

# Setup some objects
####################################################
Comment = Struct.new('Comment', :user, :post)
Post = Struct.new('Post', :title)
User = Struct.new('User', :name)
post = Post.new(title: String.new('A title'))
user = User.new(name: String.new('Sparauao Rossi'))
comment = Comment.new
####################################################

result = NewlyAddedComment.new
                          .has(:post)
                          .has(:comment)
                          .apply(:post, :value= => post)
                          .apply(:comment, :value= => comment, :post= => post, :user= => user)
                          .has(:user)
                          .apply(:user, new_name: 'Derrik')

pp result.comment
pp result.post
pp result.user
