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

	def setup
    # no setup
	end # end setup

  def test_action_simple_action_define
    myfsm = BlankStateMachine.new
    myfsm.define_action :action1 do
        puts "stuff"
      end # end add action
    
    assert_equal(:action1 , myfsm.actions[0], "Check name of loose action")
    
    # Check method there by just calling it...
    myfsm.action1
    # Hopefully that did not throw an exception.
    #assert(myfsm.test1_action==15 , "Check blocks return value is ok.")
    
    # Lets add another
    myfsm.define_action :action2
    myfsm.action2
    assert(myfsm.actions.length==2, "Check 2 entries added to actions list")
    
  end # end test

  def test_state_simple_state_define
    
    myfsm = BlankStateMachine.new
    myfsm.define_action :action1 do
        puts "stuff"
      end # end add action
    
    myfsm.attach_states(:action1 , :STATEA , :STATEB)
    assert(myfsm.states.include?(:STATEA) , "Check stateA added")
    assert(myfsm.states.include?(:STATEB) , "Check stateB added")
    
    # Catch missing objects
    assert_raises RuntimeError do
      returned_obj = myfsm.action(:action3)
    end # end assert
    
    
  end # end state test
  
	def teardown
	end # end teardown/clearup
	
end # end class

