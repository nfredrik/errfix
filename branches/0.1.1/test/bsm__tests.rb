# Copyright (c) 2008 Peter Houghton 
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


require 'rubygems'
require 'test/unit'
require 'errfix'


class BSM__tests < Test::Unit::TestCase

  # 1 Dimensional State tables
	TEST1_CSV="test1.csv"           # Simple 2 state 2 action table
	TEST2_1LINE_CSV="test2.csv"     # Only has 1 line
	TEST3_0LINE_CSV="test3.csv"     # Has no lines
	TEST4_CSV="test4.csv"           # Line with fork, UNIX format txt
	TEST5_CSV="test5.csv"           # Several states in a row, single file
	TEST9_CSV="test9.csv"           # Line with loop backs, DOS format txt
  TEST10_CSV="test10.csv"         # Line with fork, DOS format txt
  
  # 2 Dimensional State tables
  TEST1_2d_CSV="test1_2d.csv"           # Simple 2 state 2 action table
	TEST2_2d_1LINE_CSV="test2_2d.csv"     # Only has 1 line
	TEST3_2d_0LINE_CSV="test3_2d.csv"     # Has no lines
	TEST4_2d_CSV="test4_2d.csv"           # Line with fork, UNIX format txt
	TEST5_2d_CSV="test5_2d.csv"           # Several states in a row, single file
	TEST9_2d_CSV="test9_2d.csv"           # Line with loop backs, DOS Format txt
  TEST10_2d_CSV="test10_2d.csv"         # Line with fork, DOS format txt

	def setup
    # no setup
	end # end setup

 
  # Define a simple model with guarded transitions
  # Check guard itself
  #
	def test_guarded_simple_dsl
 		smc = StateModelCreator.new
    smc.define_action :action1 do
      @done_action1 = true
    end # end action
    
    smc.define_action :action2 do
      @done_action2 = true
    end # end action
    
    smc.define_guard_on :action2 do
      if @done_action1 && !@done_action2
        guard=true
      else
        guard=false
      end # end if   
      guard
    end # end guard
      
  	smc.attach_transition(:STATEA,:action1,:STATEB)
  	smc.attach_transition(:STATEB,:action2,:STATEA)
      
    sm = smc.state_machine 

    assert(sm.guarded_actions.include?(:action2) , "Check action2 is identified as being guarded")
    assert(!sm.guarded_actions.include?(:action1) , "Check action1 is identified as not being guarded")
    
    assert_equal(false , sm._guard_on_action2, "check guard returns false as default")
     
    # Create the Graphiz graph object, see if it fails...
  	sm_graph = sm.create_dot_graph	
  	sm_graph.output("../test/test_guard_dsl_1.dot")
  	
 		# Check standard length walk
 		#the_walk = sm.random_walk(:STATEA)
 		sm.state=:STATEA
 		assert_equal(:STATEB , sm.action1 , "Check at StateB")
 		assert_equal(true , sm._guard_on_action2 , "Check Guard returns correct value")
      
	end # end test
 	
 	# Loaded CSV files should create methods on StateMachine.
 	# Just as DSL created STateMachines have.
 	#
 	def test_sm_load_table_simple
    smc = StateModelCreator.new(true)	  
		sm = smc.load_table(TEST1_CSV)
		sm.state="STATEA"
		# Check if action method is added
		sm.action1
		#
		sm.action2
 
  end # end def
 	
 	# Does using two instances of the state_machine cause cross deployment of methods
 	#
 	def test_concurrent_use
 	  
    smc1 = StateModelCreator.new(true)
 		smc1.define_action :a1
 		smc1.define_action :b1
 		smc1.attach_transition(:STATEA,:a1,:STATEB)
 		smc1.attach_transition(:STATEB,:b1,:STATEA)
 	  sm1 = smc1.state_machine
 	  sm1.state=:STATEA
 	  
    smc2 = StateModelCreator.new(true)
 		smc2.define_action :a2
 		smc2.define_action :b2
 		smc2.attach_transition(:STATEA,:a2,:STATEB)
 		smc2.attach_transition(:STATEB,:b2,:STATEA)
 	  sm2 = smc2.state_machine	  
 	  sm2.state=:STATEA
 	  
 	  assert_raises NoMethodError , "Check actions/methods are only added to one instance." do
 	    sm2.a1
    end # end assert raises
 	  
 	  
  end  # end test
 	
 	def a_guarded_state_machine
 	  smc = StateModelCreator.new(true)
 		smc.define_action :click_home
 		smc.define_action :view_content

 		smc.define_guard_on :view_content do
 		  # You can only view content if you are logged in.
 		  if @logged_in
 		      guard=true
		  else
		      guard=false
		  end # end if else
		  guard
		end # end guard

    smc.define_guard_on :click_log_in do
      # You can't log in if you are already logged in.
      if @logged_in
 		    guard=false
		  else
		    guard=true
		  end # end if else
		  guard
    end # end guard

    smc.define_action :click_log_in do
      @logged_in=true
    end # end action
    
    smc.define_action :show_more 
    
 		smc.attach_transition(:HOME,:view_content,:SHOWING_CONTENT)
 		smc.attach_transition(:SHOWING_CONTENT,:show_more,:MORE_CONTENT)
 		smc.attach_transition(:HOME,:click_log_in,:LOG_IN_COMPLETE)
 		smc.attach_transition(:LOG_IN_COMPLETE,:click_home,:HOME)
 		
 		#smc = smc.state_machine
 		
 		return smc
  
  end # procedure for creating a state machine
 	
 	# Define a model with guarded transitions.
 	# Check it is correctly navigated,
 	#
 	def test_random_walk_guarded_complex_dsl
 	  smc = a_guarded_state_machine
 	  sm = smc.state_machine
 	  
    # Create the Graphiz graph object, see if it fails...
	  sm_graph = sm.create_dot_graph	
	  sm_graph.output("../test/test_guard_dsl_2.dot")
    
    assert_equal(4 , sm.states_store.length , "Check for 4 states")

 		# Check creates a real walk
 		the_walk = sm.random_walk(:HOME)
 		assert_equal(Walk.new.class, the_walk.class , "Check random walk returns Walk instance" )
 		
 		puts "test_random_walk_guarded_complex_dsl"
 		puts the_walk
 		
 		# When guards are in place, walk can only be length 4
 		assert_equal(4 ,the_walk.transitions.length , "Check Walk is length 4")
 	
 	end # end

  # Test that Statemachine variables (from custom methods) can be read.
  def test_read_action_variables
    smc = a_guarded_state_machine
    
    smc.define_reader :logged_in do;  @logged_in ;end
    sm = smc.state_machine
    sm.state=:HOME
    sm.click_log_in
    assert_equal(:LOG_IN_COMPLETE, sm.state , "Check Logged in.")
    puts
    puts "Variables:"
    puts sm.read_logged_in
    assert(sm.read_logged_in , "Check logged in is accessible and true")

  end # test can read variabled created in action methods
  
	def teardown
	end # end teardown/clearup
	
end # end class

