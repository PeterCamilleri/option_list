#A formal testing frame for the option list class.
#Execute this file to perform the tests.

require_relative '../lib/option_list'
require          'minitest/autorun'

class OptionTest
  def initialize(opt)
    @opt = opt
  end
  
  def test(*args)
    o = @opt.select(args)
  end
end

class OptionListTester < MiniTest::Unit::TestCase
  $do_this_only_one_time = ""
  
  def initialize(*all)
    if $do_this_only_one_time != __FILE__
      puts
      puts "Running test file: #{File.split(__FILE__)[1]}" 
      $do_this_only_one_time = __FILE__
    end
    
    super(*all)
  end

  def test_that_it_rejects_bad_specs
    #Reject empty argument lists.
    assert_raises(ArgumentError) { @x = OptionList.new }    
    assert_raises(ArgumentError) { @x = OptionList.new([])}
    assert_raises(ArgumentError) { @x = OptionList.new({})}
    
    #Reject if not an array or a hash.
    assert_raises(ArgumentError) { @x = OptionList.new(4) }
    assert_raises(ArgumentError) { @x = OptionList.new('foobar') }    

    #Reject for too few arguments.
    assert_raises(ArgumentError) { @x = OptionList.new([]) }
    assert_raises(ArgumentError) { @x = OptionList.new([:foo]) }
    assert_raises(ArgumentError) { @x = OptionList.new([:foo, :bar]) }
    
    #Reject for the wrong types of arguments.
    assert_raises(ArgumentError) { @x = OptionList.new(['foo', :foo,  :bar] )}
    assert_raises(ArgumentError) { @x = OptionList.new([:foo,  'foo', :bar] )}
    assert_raises(ArgumentError) { @x = OptionList.new([:foo,  :foo,  'bar'])}
    assert_raises(ArgumentError) { @x = OptionList.new({'foo' => 42})}
    
    #Reject for duplicate categories.
    assert_raises(ArgumentError) { @x = OptionList.new([:foo, :lala, :bar], [:foo, :kung, :east]) }
    assert_raises(ArgumentError) { @x = OptionList.new([:foo, :lala, :bar], {:foo => :kung}) }
    assert_raises(ArgumentError) { @x = OptionList.new({:foo => :lala}, {:foo => :kung}) }
    #The following is not detectable since :foo => :kung overwrites :foo => :lala
    #assert_raises(ArgumentError) { @x = OptionList.new({:foo => :lala, :foo => :kung}) }
    
    #Reject for duplicate options.
    assert_raises(ArgumentError) { @x = OptionList.new([:foo, :bar, :bar]) }
    assert_raises(ArgumentError) { @x = OptionList.new([:foo, :foo, :bar], [:bla, :food, :bar]) }    

    #Reject for nil in the wrong position.    
    assert_raises(ArgumentError) { @x = OptionList.new([:foo, :bar, nil]) }
  end
  
  def test_that_the_methods_were_added
    ol1 = OptionList.new([:history, :history, :nohistory], {:pg_len => 42})
    o = ol1.select
  
    assert_respond_to(o, :history)
    assert_respond_to(o, :history? )
    assert_respond_to(o, :nohistory? )
    assert_respond_to(o, :pg_len)

    ol2 = OptionList.new([:history, nil, :history, :nohistory]) 
    o = ol2.select
    
    assert_respond_to(o, :history)
    assert_respond_to(o, :history? )
    assert_respond_to(o, :nohistory? )
    assert_raises(NoMethodError) { o.send((nil.to_s+'?').to_sym) }
  end

  def test_that_it_rejects_bad_selections
    ol1 = OptionList.new([:history, :history, :nohistory], {:pg_len => 42})
  
    #Reject if options are not an array or a hash.
    assert_raises(ArgumentError) { ol1.select(45) }
    
    #Reject if the option is not a symbol.
    assert_raises(ArgumentError) { ol1.select([34]) }
    
    #Reject if the category is not a symbol.
    assert_raises(ArgumentError) { ol1.select({'page_len'=>77}) }
    
    #Reject if the symbol is not one defined.
    assert_raises(ArgumentError) { ol1.select([:foobar]) }
    assert_raises(ArgumentError) { ol1.select({:history=>:foobar}) }
    
    #Reject on duplicate symbol from the same category.
    assert_raises(ArgumentError) { ol1.select([:history, :history]) }
    assert_raises(ArgumentError) { ol1.select([:history, :nohistory]) }   
    assert_raises(ArgumentError) { ol1.select([:history, {:history=>:nohistory}]) }
    assert_raises(ArgumentError) { ol1.select([{:history=>:history}, {:history=>:nohistory}]) }
    
    #Reject on an undefined category.
    assert_raises(ArgumentError) { ol1.select({:zoo => 999})}
  end
  
  def test_that_it_handles_good_options
    #ol1 test series.
    ol1 = OptionList.new([:history, :history, :nohistory], {:pg_len => 42})
    
    o = ol1.select
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)
    assert_equal(o.pg_len, 42)    
    
    o = ol1.select([])
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)
    assert_equal(o.pg_len, 42)    
    
    o = ol1.select([:history])
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)
    assert_equal(o.pg_len, 42)    
    
    o = ol1.select([:nohistory])
    refute(o.history?)
    assert(o.nohistory?)
    assert_equal(o.history, :nohistory)
    assert_equal(o.pg_len, 42)    

    o = ol1.select({:history=>:history})
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)
    assert_equal(o.pg_len, 42)    
    
    o = ol1.select({:history=>:nohistory})
    refute(o.history?)
    assert(o.nohistory?)
    assert_equal(o.history, :nohistory)
    assert_equal(o.pg_len, 42)    

    o = ol1.select({:pg_len=>55})
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)
    assert_equal(o.pg_len, 55)
    
    o = ol1.select({:history=>:history, :pg_len=>55})
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)
    assert_equal(o.pg_len, 55)

    o = ol1.select({:history=>:nohistory, :pg_len=>55})
    refute(o.history?)
    assert(o.nohistory?)
    assert_equal(o.history, :nohistory)
    assert_equal(o.pg_len, 55)

    o = ol1.select([:history, {:pg_len=>55}])
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)
    assert_equal(o.pg_len, 55)

    o = ol1.select([:nohistory, {:pg_len=>55}])
    refute(o.history?)
    assert(o.nohistory?)
    assert_equal(o.history, :nohistory)
    assert_equal(o.pg_len, 55)

    
    #ol2 test series.
    ol2 = OptionList.new([:history, nil, :history, :nohistory]) 
    
    o = ol2.select([:history])
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)

    o = ol2.select([:nohistory])
    assert(o.nohistory?)
    refute(o.history?)
    assert_equal(o.history, :nohistory)

    o = ol2.select([])
    refute(o.history?)
    refute(o.nohistory?)
    assert(o.history.nil?)
  end
  
  def test_that_mandatory_parms_work
    ol2 = OptionList.new([:history, false, :history, :nohistory]) 

    o = ol2.select([:history])
    assert(o.history?)
    refute(o.nohistory?)
    assert_equal(o.history, :history)

    o = ol2.select([:nohistory])
    assert(o.nohistory?)
    refute(o.history?)
    assert_equal(o.history, :nohistory)

    assert_raises(ArgumentError) { ol2.select() }
  end
  
  def test_that_it_does_not_munge_parms
    parm1 = [:history, false, :history, :nohistory]
    parm2 = parm1.clone
    ol2 = OptionList.new(parm1)
    assert_equal(parm1, parm2)
  end
  
  def test_that_the_select_block_works
    ol3 = OptionList.new([:history, nil, :history, :nohistory],
                          fuel1: :matter, fuel2: :antimatter) do |opt|
      fail "The :history option must be set." if opt.history.nil?
      fail "Improper fuel mix." unless opt.fuel1 == :matter && opt.fuel2 == :antimatter
    end
    
    t = OptionTest.new(ol3)
    
    assert_raises(RuntimeError) { t.test() }
    assert_raises(RuntimeError) { t.test(:nohistory, fuel2: :income_tax) }
    #Really though, this should work! Both anti-matter and income tax
    #destroy anything that that they come into contact with.
  end
end
