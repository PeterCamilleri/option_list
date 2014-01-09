require 'set'

#=== The file option_list.rb and the class \OptionList.
#This file contains the code for the \OptionList class that implements smart
#and easy options for functions. It has the virtue of defining function
#options clearly in a single place instead of spread out in complex code.
#A classic but unclear sequence in many functions is the use of boolean values
#to control or switch on or off some option. For example consider the well 
#known readline function:
# cmd = readline(">", false)
#See the boolean at the end? It says "false". What is "false"? Who knows? You 
#need to dig deeper or guess or just cut and paste without understanding. What
#if, instead, the code looked like:
# cmd = readline(">", :nohistory)
#The boolean has been replaced by something a lot clearer. The problem with
#such clarity is that it involves a lot more effort than the lazy boolean. The
#\OptionList class aims to solve that issue by making useful, flexible options
#just about as easy to use as the lazy way.
#==== Warning: This code is most opinionated! ;-)
#The philosophy and opinion expressed through this code is that errors should
#be detected as close to the point of error as possible and that an error is
#preferable to running with potentially incorrect results. As a result, it
#will be noted that the programmer does not hesitate to use the error, a wrapper
#of the "fail" keyword, liberally throughout the code to achieve this end.
#Complimentary to this is the idea that the library (gem) writer should do as
#much of the "heavy lifting" as possible, with clear, detailed documentation so
#that the library (gem) user does not have to work hard or be lost or confused.
#Only time will tell to what extent these lofty goals have been achieved. 
#Hopefully, with good feedback, this and other code libraries will improve.
#=== Version 1.0.1
#This version represents a major overhaul of the \OptionList class. In 
#particular, the selected option data and the dynamic methods used to access
#that data are no longer contained in the option list object but instead in
#a singleton subclass of Hash that is returned by the select method. There 
#are several advantages to this, but the main one is that since \OptionList
#objects now only contain specification and default values, they are much more
#thread safe than before. While there is nothing multi-threaded about the
#\OptionList class itself, it is reasonable to assume that a function option
#handler could very easily end up embedded in such an environment. In fact, my
#first major test of the class ran into this exact issue.
#=== Version 1.1.0
#Added a default value of false to signify that no default exists for a 
#mandatory parameter.
#Modified processing of array specs to avoid side effects in the parameters.
class OptionList

  #The option list code version.
  def self.version
    '1.1.1'
  end
  
  #The option list code version. This is a redirect to the class method.
  def version
    self.class.version
  end

  #Create an option list from an array of option specifications. These 
  #specifications consist of a number of array specifications and hash 
  #specifications. These are described below:
  #==== Array Specification
  #Array specifications are used in cases where an option category may be one
  #of a fixed number of distinct symbol values or optionally nil to represent 
  #no selection.
  #In this form of specification, the first element of the array is the
  #category of the option, and the second and following entries are the 
  #allowed values for that category. The second element has a special role. It
  #is the default value for the category. This value may be one of:
  #* A symbol - The default symbolic value for this option.
  #* nil - The default value is nil and this setting is optional.
  #* false - There is no default value and this setting is mandatory.
  #The symbols used in each category must be unique across
  #all of the categories in the option list.
  #==== Hash Specification
  #Hash specifications are used to specify options that do not have a fixed set
  #of possible values. In this form of specification, the hash key symbol is 
  #the category and the hash value is the default value for the category. It 
  #may be nil or any other type or value. Allowed values are not listed.
  #==== Example:
  # @opt_list = OptionList.new([:history, :history, :nohistory], {:page_len => 42})
  #==== Parameters:
  #* option_specs - The comma separated option specifications, made into an 
  #  array by the splat operator.
  #* select_block - An optional block of code that is called when selections
  #  have been made. This allows for custom validations to be applied at that
  #  point. This block should accept one argument, a reference to the option
  #  list value object that is calling it for validation.
  #==== Dynamic Methods:
  #As option specifications are added, new methods are created in the value 
  #object to allow for easy access to the option information. If the above 
  #example were processed, the following methods would be added to the value
  #returned by the select method:
  #* history - would return the value of the :history category.
  #* history? - would return true if the :history option where active.
  #* nohistory? - would return true if the :nohistory option were active.
  #* page_len - would return the value of the :page_len category.
  #==== Exceptions:
  #* ArgumentError for a number of invalid argument conditions.
  def initialize(*option_specs, &select_block)
    error "Missing option specifications." if option_specs.empty?
    @mandatory  = Array.new
    @categories = Hash.new
    @default    = Hash.new
    
    option_specs.each do |spec|
      if spec.is_a?(Hash)
        hash_spec(spec)
      elsif spec.is_a?(Array)
        array_spec(spec)
      else
        error "Found #{spec.class} instead of Hash or Array."
      end
    end
    
    @select_block = select_block
  end

  #From the possible options, select the actual, in force, options and return
  #an access object for use in the code. These options may take several forms:
  #=== Types of option data:
  #* A symbol - For categories with a specified symbol list, simply list one
  #  of the allowed symbols.
  #* A hash - For any type of category, a hash may be used in the the form
  #  {category => value}. Note that for categories with a specified symbol list
  #  the value must be a symbol in the list.
  #* Mixed - Symbols and hashes can be mixed in an array (see below on how this
  #  is done) Note: Option order does not matter.
  #Some examples:
  # o = foo(:sedan, :turbo)
  # o = foo({:style=>:sedan})
  # o = foo(page_len: 60) 
  # o = foo(:sedan, :turbo, page_len: 60)
  # o = foo(style: :sedan, page_len: 60)
  #=== Passing in option data:
  #The caller of this method may pass these options in a number of ways:
  #==== Array (via a splat)
  #Given the example shown in the new method, consider:
  # def test(count, *opt)
  #   @opt_list.select(opt)
  #   #etc, etc, etc...
  # end
  #With the caller now looking like:
  # test(43, :history)
  #==== Array (explicit)
  #An alternative strategy, where the use of splat is not desired, is to simply
  #have an array argument, as below:
  # def test(*arg1, opt)
  #   @opt_list.select(opt)
  #   #etc, etc, etc...
  # end
  #With the caller now looking like:
  # test(34, 53, 76, 'hike!', [:history])
  #==== Hash
  #Options may also be passed via a hash.
  # test(34, 53, 76, 'hike!', {:history=>:history, :page_len=>55})
  # test(34, 53, 76, 'hike!', history: :history, page_len: 55)
  #==== Symbol
  #If only a single option is required, it can be passed simply as:
  # test(34, 53, 76, 'hike!', :history)
  #==== Parameters:
  #* selections - An array of the options passed into the client function, usually
  #  with the splat operator. Note that if select is called with no arguments,
  #  all of the default values will be selected.
  #==== Returns:
  #An option value object which is a singleton subclass of the Hash class.
  #==== Exceptions:
  #* ArgumentError for a number of invalid argument conditions.
  #==== Notes:
  #After processing the selections, the selection validation block is called 
  #if one was defined for the constructor.
  def select(selections=[])
    selections = [selections] unless selections.is_a?(Array)
    selected = process_selections(selections)
    
    @mandatory.each do |cat|
      error "Missing mandatory setting #{cat}" unless selected[cat]
    end
    
    @select_block.call(selected) if @select_block
    selected
  end
  
  private  #Private stuff follows.

  #Process a list of option selections.
  def process_selections(selections)
    selected, dup = @default.clone, Set.new
    
    selections.each do |opt|
      if opt.is_a?(Symbol)
        symbolic_selection(opt, selected, dup)
      elsif opt.is_a?(Hash)
        hash_selections(opt, selected, dup)
      else
        error "Found #{opt.class} instead of Hash or Symbol."
      end
    end
    
    selected
  end
  
  #Return a internal category marker constant for value entries.
  def value_entry
    'A value entry.'
  end
  
  #Process an array spec that lists all the valid values for an option. See
  #the new method for more information on these specs.
  def array_spec(spec)
    category, default, spec_len = spec[0], spec[1], spec.length
    error "Invalid number of entries for #{category}." unless spec_len > 2
    add_option_reader(category)
    array_spec_default(category, default)
    array_spec_tail_rest(category, spec[2...spec_len])
  end
  
  #Process the first element of the array spec tail.  
  def array_spec_default(category, opt)
    opt && array_spec_single(category, opt)
    @default[category] = opt
    @mandatory << category if opt == false
  end
  
  #Process the rest of the array spec tail.  
  def array_spec_tail_rest(category, spec_tail_rest)
    spec_tail_rest.each do |opt|
      if opt
        array_spec_single(category, opt)
      else
        error "The values nil/false are only allowed as the default option."
      end
    end
  end
  
  #Process a single array spec option
  def array_spec_single(category, opt)
    duplicate_entry_check(@categories, opt, 'option')
    @categories[opt] = category
    add_option_tester(category, opt)
  end
  
  #Process a hash spec that lists only the default value for an option. See
  #the new method for more information on these specs.
  def hash_spec(spec)
    error "Hash contains no specs." unless spec.length > 0

    spec.each do |category, value|
      add_option_reader(category)
      set_default_option_value(category, value)
      @mandatory << category if value == false
    end
  end
  
  #Set the default value of a value entry.
  def set_default_option_value(category, value)
    @categories[category] = value_entry
    @default[category] = value    
  end
  
  #Process a symbolic option selection.
  #==== Parameters:
  #* option - a symbol to process.
  #* selected - a hash of selected data.
  #* dup - a set of categories that have been set. Used to detect duplicates.
  def symbolic_selection(symbol_option, selected, dup)
    missing_entry_check(@categories, symbol_option, 'option')
    category = @categories[symbol_option]
    hash_option_dup_check(category, dup)
    selected[category] = symbol_option
  end
  
  #Process a hash of option selection values.
  #==== Parameters:
  #* options - a hash of options to process.
  #* selected - a hash of selected data.
  #* dup - a set of categories that have been set. Used to detect duplicates.
  def hash_selections(hash_options, selected, dup)
    hash_options.each do |category, value|
      missing_entry_check(@default, category, 'category')

      hash_option_value_check(category, value)
      hash_option_dup_check(category, dup)
      selected[category] = value
    end
  end
  
  #Validate a hash option value.
  def hash_option_value_check(value_category, value)
    if (@categories[value_category] != value_entry) && value
      error "Found #{value.class}, expected Symbol." unless value.is_a?(Symbol)
      error "Invalid option: #{value}." unless @categories[value] == value_category
    end
  end
 
  #Add to set with no duplicates allowed. 
  def hash_option_dup_check(category, dup)
    error "Category #{category} has multiple values." unless dup.add?(category)
  end
  
  #Add query method for the selected category.
  def add_option_reader(name)
    duplicate_entry_check(@default, name, 'category')
    @default.define_singleton_method(name) { self[name] }
  end

  #Add a query method (eg: has_stuff? ) for the selected option.
  def add_option_tester(target, value)
    qry = (value.to_s + '?').to_sym
    @default.define_singleton_method(qry) { self[target] == value}
  end
  
  #Flag any duplicate entry errors.
  def duplicate_entry_check(target, entry, detail)
    error "Found #{entry.class}, expected Symbol." unless entry.is_a?(Symbol)   
    error "Duplicate #{detail}: #{entry}" if target.has_key?(entry)
  end
  
  #Flag any missing entry errors.
  def missing_entry_check(target, entry, detail)
    error "Unknown #{detail}: #{entry}" unless target.has_key?(entry)
  end

  #Fail with an argument error.
  def error(messsage)
    fail(ArgumentError, messsage, caller)
  end
end
