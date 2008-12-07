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
require 'errfix'

# Example Test Driver
# This pretends to be a test driver, to support unit tests
#
class EgTestDriver

  def initialize(use_symbols=false)
    @transitions_list=Array.new
    @states_list=Array.new
    @symbols=use_symbols
  end # end initialize
  
  def push_states(state_sym,state_str)
    if @symbols
      @states_list.push state_sym
    else
      @states_list.push state_str
    end # end if
  end # end emthod
  
  # Test state methods, record that they were touched...
  def test_STATEA  
    push_states(:STATEA , "STATEA")
  end # end test state
  
  def test_STATEB
    push_states(:STATEB , "STATEB")
  end # end test state
  
  def test_STATEC
    push_states(:STATEC , "STATEC")
  end # end test state
  
  def test_STATED
    push_states(:STATED , "STATED")
  end # end test state
  
  def test_STATEE
    push_states(:STATEE , "STATEE")
  end # end test state
  
  
  # Actions, record that they were touched...
  def action1
    if @symbols
      @transitions_list.push TransitionHolder.new(:STATEA,:action1,:STATEB)     
    else
      @transitions_list.push TransitionHolder.new("STATEA","action1","STATEB")
    end # end if
  end # end action1

  def action2
    if @symbols
      @transitions_list.push TransitionHolder.new(:STATEB,:action2,:STATEC)
    else
      @transitions_list.push TransitionHolder.new("STATEB","action2","STATEC")
    end # end
  end # end action2

  def action3
    if @symbols
      @transitions_list.push TransitionHolder.new(:STATEC,:action3,:STATED)
    else
      @transitions_list.push TransitionHolder.new("STATEC","action3","STATED")
    end # end
  end # end action3
  
  def action4
    if @symbols
      @transitions_list.push TransitionHolder.new(:STATEC,:action4,:STATEE)
    else
      @transitions_list.push TransitionHolder.new("STATEC","action4","STATEE")
    end # end
  end # end action4

  def states_tested
    return @states_list
  end # end states travelled

  def transitions_travelled
    return @transitions_list
  end # end transitions travelled

end # end class
