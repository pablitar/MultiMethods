class MultiMethodImplementation
  def initialize(parameters, implementation)
    @matchers = parameters.map { |param| self.createMatcher(param) }
    @implementation = implementation
  end

  def createMatcher(param)
    if(param.is_a? Module)
      lambda {|value| value.is_a? param}
    else
      if(param.is_a? Proc)
        param
      else
        lambda {|value| value.eql? param}
      end
    end
  end

  def execute(obj, *args)
    obj.instance_exec *args, &@implementation
  end

  def matches(args)
    @matchers.zip(args).flat_map { |pair|
      pair[0].call(pair[1])
    }.all?
  end
end

class Multimethod

  attr_accessor :implementations
  def initialize(selector, block)
    @selector = selector
    self.implementations = []
    if(block.is_a? Proc)
      self.instance_eval &block
    else
      self.implementations = block
    end
  end

  def define_for(parameters, &implementation)
    self.implementations << MultiMethodImplementation.new(parameters, implementation)
  end

  def duck(*messages)
    lambda { |obj| messages.all? { |a_msg|
      obj.respond_to? a_msg
     }
    }
  end

  def call(obj, *args)

    implementation = self.implementations.find {|impl| impl.matches(args) }

    if(!implementation.nil?)
      implementation.execute(obj, *args)
    else
      raise "No implementation of #{@selector} matches args"
    end
  end

  def merge(multimethod)
    new_implementations = self.implementations.clone
    if(!multimethod.nil?)
      new_implementations = multimethod.implementations + new_implementations
    end

    Multimethod.new(@selector, new_implementations)
  end
end

class Module
  def multimethod(selector, &block)
    define_multimethod_with(self, selector, block)
  end

  def multimethods
    @multimethods = @multimethods || {}
    @multimethods
  end

  def get_multimethod(selector)
    first_ancestor = self.ancestors[1]
    super_multimethod = if (first_ancestor.nil?) then nil else first_ancestor.get_multimethod(selector) end
    if(!super_multimethod.nil?)
      super_multimethod.merge(self.multimethods[selector])
    else
      self.multimethods[selector]
    end
  end

  def define_multimethod_with(provider, selector, block)
    provider.multimethods[selector] = Multimethod.new(selector, block)

    provider.send :define_method, selector do |*args|
      self.singleton_class.get_multimethod(selector).call(self, *args)
    end
  end

  def self_multimethod(selector, &block)
    define_multimethod_with(self.singleton_class, selector, block)
  end
end