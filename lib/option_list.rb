require 'set'

#=== The file option_list.rb and the class \OptionList.
#This file contains the code for the \OptionList class that implements smart
#and easy options for functions. It has the virtue of defining function
#options clearly in a single place instead of spread out in complex code.
#==== User's Guide
#Most of the documentation for this gem has been moved to
#{Option List User's Guide}[http://teuthida-technologies.com/guides/OL_UG_Version_1_1_1.pdf]
#====Version 1.1.1
#Embraced reek and git and created the user's guide to pair down rdoc mark up
#to be less obtrusive to the code.
#=== Version 1.1.0
#Added a default value of false to signify that no default exists for a
#mandatory parameter.
#Modified processing of array specs to avoid side effects in the parameters.
class OptionList

  #The option list code version.
  def self.version
    OptionList::VERSION
  end

  #The option list code version. This is a redirect to the class method.
  def version
    OptionList::VERSION
  end

  #Create an option list from an array of option specifications.
  #==== Parameters:
  #* option_specs - The comma separated option specifications, made into an
  #  array by the splat operator.
  #* select_block - An optional block of code that is called when selections
  #  have been made. This allows for custom validations to be applied at that
  #  point. This block should accept one argument, a reference to the option
  #  list value object that is calling it for validation.
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
  #an access object for use in the code.
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
