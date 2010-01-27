require File.dirname(__FILE__) + '/../test_helper'

class SanityTest < ActiveSupport::TestCase
  def test_is_sane
    assert true
  end

  should "be true" do
    assert true
  end

  should "connect to database" do
    User.generate_with_protected!(:firstname => 'Testing connection')
    assert_equal 1, User.count(:all, :conditions => {:firstname => 'Testing connection'})
  end
end
