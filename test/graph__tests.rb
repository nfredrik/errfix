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


class Graph__tests < Test::Unit::TestCase

	def setup

	end # end setup


# to_s should return a string representation of the graph in the dot language.
# most of whats added to the graph will translate to something than is in this...
  def test_graph_to_s
    sut_graph = Graph.new
    sut_graph.name="test_graph"  
    sut_graph.type=:digraph
    sut_graph.node_style=:ellipse
    #sut_graph.add_node "TEST1"
    #sut_graph.add_node "TEST2"
    sut_graph.add_edge("TEST1" , "TEST2" , "take_me_to_test_2")
    
    
    returned_obj = sut_graph.to_s
    assert( returned_obj.instance_of?(String) , "Check to_s returns String, returns: #{returned_obj.class}" )
    assert(returned_obj.scan(/test_graph/).length==1 , "Check once occurence of graph name in dot to_s.")
    assert(returned_obj.scan(/digraph test_graph/).length==1 , "Check graph type and name in dot to_s.")   
    assert(returned_obj.scan(/shape = ellipse/).length==1 , "Check graph node style in dot to_s.")   
    #assert(returned_obj.scan(/TEST1\;/).length==1 , "Check that Node definition is included: TEST1;")
    #assert(returned_obj.scan(/TEST2\;/).length==1 , "Check that Node definition is included: TEST2}")
    assert(returned_obj.scan(/label = \"take_me_to_test_2"/).length==1 , "Check that arc label is included")
    
  end # end test

  # Test that the graph class will not let you to_s on an incomplete graph
  def test_graph_to_s_incomplete
    sut_graph = Graph.new
     sut_graph.name="test_graph"  
     #sut_graph.type=:digraph
     sut_graph.node_style=:ellipse
     
     sut_graph.add_edge("TEST1" , "TEST2" , "take_me_to_test_2")
     assert_raises RuntimeError do
       returned_obj = sut_graph.to_s
     end # end assert
  end # end test




	def teardown
	end # end teardown/clearup
	
end # end class

