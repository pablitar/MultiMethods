require 'rspec'
require_relative '../src/multi_methods'

class SuperStringUtils
  multimethod :concat do
    define_for [String, String] do |s1, s2|
      s2 + s1
    end

    define_for [String, Array] do |s, a|
      a.join s
    end
  end
end

class StringUtils < SuperStringUtils
  multimethod :concat do
    define_for [nil] do |o|
      nil
    end

    define_for [String, duck(:nombre, :apellido)] do |s, p|
      "#{s} #{p.nombre} #{p.apellido}!"
    end

    define_for [String, -1] do |s, n|
      s.reverse
    end

    define_for [String, proc { |o| o.is_a?(Integer) && (o.odd? or o == 42) }] do
      true
    end

    define_for [String, String] do |s1, s2|
      s1 + s2
    end

    define_for [String, Integer] do |s, i|
      s * i
    end

    define_for [Array] do |a|
      a.join
    end
  end


  self_multimethod :concat do
    define_for [String, String] do |s1, s2|
      s1 + s2
    end

    define_for [String, Integer] do |s, i|
      s * i
    end
  end
end

class Persona
  attr_accessor :nombre, :apellido

  def initialize
    @nombre = 'Johann Sebastian'
    @apellido = 'Mastropiero'
  end
end

describe "multimethods" do
  utils = StringUtils.new
  it "should have a concat multimethod with types" do
    expect(utils.concat('hola', 'mundo')).to eq('holamundo')
    expect(utils.concat('hola', 4)).to eq('holaholaholahola')
    expect(utils.concat(['hola', ' ', 'mundo'])).to eq('hola mundo')
  end

  it "should have a concat multimethod with procs and values" do
    expect(utils.concat(nil)).to eq(nil)
    expect(utils.concat('hola', -1)).to eq('aloh')
    expect(utils.concat('hola', 45)).to eq(true)
  end

  it "should support duck typing" do
    expect(utils.concat('Hola Sr.', Persona.new)).to eq('Hola Sr. Johann Sebastian Mastropiero!')
  end

  it "should support class multimethods" do
    expect(StringUtils.concat('hola', 'mundo')).to eq('holamundo')
    expect(StringUtils.concat('hola', 3)).to eq('holaholahola')
  end

  it "should support inheritance multimethods" do
    sutils = SuperStringUtils.new
    expect(sutils.concat('hola', 'mundo')).to eq('mundohola')
    expect(utils.concat('-', ['hola', 'mundo'])).to eq('hola-mundo')
  end
end