require File.dirname(__FILE__) + '/spec_helper.rb'

describe "excesselt" do
  
  describe "When a developer wants to transform their hello world xml" do
        
    before do
    
      module TestHelper
        def error_text_in_parent
          error("Text is not allowed within a parent node!") unless (text.strip == '')
        end
        def uppercase_text
          add text.upcase
        end
        def text
          self.to_xml
        end
      end
      
      @stylesheet = Class.new(Excesselt::Stylesheet) do
        def rules
          render('parent > child')     { builder.p(:style => "child_content" ) { child_content }  }
          render('parent')             { builder.p(:style => "parent_content") { child_content }  }          
          helper TestHelper do
            render('parent.explode > text()', :with => :a_method_that_doesnt_exist)
            render('parent > text()', :with => :error_text_in_parent)
            render('text()', :with => :uppercase_text)
          end
        end
      end
      
    end
    
    it "should transform a hello world document according to a stylesheet" do
      xml = <<-XML
        <parent>
          <child>Hello World</child>
        </parent>
      XML
      expected = <<-EXPECTED
        <p style="parent_content">
          <p style="child_content">HELLO WORLD</p>
        </p>
      EXPECTED
      @stylesheet.transform(xml).should match_the_dom_of(expected)
    end
    
    it "should transform a goodbye document according to a stylesheet" do
      xml = <<-XML
        <parent>
          <parent>
            <child>Goodbye</child>
          </parent>
        </parent>
      XML
      expected = <<-EXPECTED
        <p style="parent_content" >
          <p style="parent_content" >
            <p style="child_content" >
              GOODBYE
            </p>
          </p>            
        </p>
      EXPECTED
      @stylesheet.transform(xml).should match_the_dom_of(expected)
    end

    describe "error handling" do
      
      it "should record errors encountered during processing" do
        xml = <<-XML
          <parent>foo</parent>
        XML
        @instance = @stylesheet.new
        @instance.transform(xml)
        @instance.errors.should == ["Text is not allowed within a parent node!"]
      end
      
      it "should record errors encountered during processing" do
        xml = <<-XML
          <parent><unexpected></unexpected></parent>
        XML
        @instance = @stylesheet.new
        lambda { @instance.transform(xml) }.should raise_exception {|e| 
          e.message.should =~ /With selector .* and included modules: \[TestHelper\]/
          e.message.should =~ /There is no style defined to handle element 'unexpected' in this context \(document, parent\)/
          
        }
      end
      
    end

  end
  
end
