require 'spec_helper'

describe String do

  it "should tell sentences" do
    "First sentence. Second sentence . Third".sentences.should eq(["First sentence", "Second sentence", "Third"])
  end

  it "should reject empty sentences" do
    "First sentence. . Third.\r\n".sentences.should eq(["First sentence", "Third"])
  end

  it "should convert to sentence" do
    "foo".to_sentence.should eq('foo. ')
    "foo.".to_sentence.should eq('foo. ')
    "foo. ".to_sentence.should eq('foo. ')
    "foo.bar".to_sentence.should eq('foo.bar. ')
  end

  it "should strip sentence" do
    "foo".strip_sentence.should eq('foo')
    "foo.".strip_sentence.should eq('foo')
    "foo. ".strip_sentence.should eq('foo')
    "foo.bar".strip_sentence.should eq('foo.bar')
    "foo.bar.".strip_sentence.should eq('foo.bar')
  end
end
