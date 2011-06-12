require 'test_helper'

class SimpleNoteApi2Test < Test::Unit::TestCase
  context SimpleNoteApi2 do
    setup do
      @simplenote = SimpleNoteApi2.new("simplenotetest@mailinator.com", "password!")
    end

    should "log in, list notes and fetch a note" do
      VCR.use_cassette('api2/get_index', :record => :none) do
        index = @simplenote.get_index
        assert_equal 11, index['count']
        note = index['data'].first
        assert note["deleted"] == 0
        assert_equal 1278200707.748862, note["modifydate"].to_f
        assert_equal "agtzaW1wbGUtbm90ZXINCxIETm90ZRiJjbgCDA", note["key"]

        note = @simplenote.get_note(note["key"])
        assert_equal "A test note", note['content']
      end
    end

    should "raise when login fails" do
      VCR.use_cassette('api2/login_failure', :record => :none) do
        error = assert_raises RuntimeError do
          @simplenote = SimpleNoteApi2.new("simplenotetest@mailinator.com", "not my password!")
          @simplenote.login
        end
        assert_equal "Login failed", error.message
      end
    end

    should "create, list, fetch and delete a note" do
      VCR.use_cassette('api2/create_note', :record => :none) do

        created_note = @simplenote.create_note(:content => "A test note")

        index = @simplenote.get_index
        assert_not_nil( index['data'].detect{|i|i['key'] == created_note['key']})

        note = @simplenote.get_note(created_note['key'])
        assert_equal "A test note", note['content']

        @simplenote.delete_note(created_note['key'])
      end
    end

    should "update a note" do
      VCR.use_cassette('api2/update_note', :record => :once) do
        key = @simplenote.create_note(:content => "A test note")['key']
        @simplenote.update_note(key, {:content => "The new content ish"})

        note = @simplenote.get_note(key)
        assert_equal "The new content ish", note['content']

        @simplenote.delete_note(key)
      end
    end

    should "return nil when you fetch a note that doesn't exist" do
      VCR.use_cassette('api2/get_note_with_bad_key', :record => :none) do
        assert_nil @simplenote.get_note("key that doesn't exist")
      end
    end

    should "raise if you try to delete a note that doesn't exist" do
      VCR.use_cassette('api2/delete_note_with_bad_key', :record => :none) do
        error = assert_raises RuntimeError do
          @simplenote.delete_note("key that doesn't exist")
        end
        assert_equal "Couldn't delete note", error.message
      end
    end
  end

end
