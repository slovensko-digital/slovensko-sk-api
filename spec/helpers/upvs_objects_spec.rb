require 'rails_helper'

RSpec.describe UpvsObjects do
  subject { described_class }

  describe '.to_structure' do
    it 'transforms Java objects to Ruby objects' do
      expect(subject.to_structure java.util.ArrayList.new).to be_an_instance_of(Array)
      expect(subject.to_structure java.util.HashMap.new).to be_an_instance_of(Hash)
    end

    it 'transforms complex object structures' do
      expect(subject.to_structure 'folderIds' => java.util.Arrays.as_list(0, 1, 2)).to eq('folder_ids' => [0, 1, 2])
      expect(subject.to_structure 'folders' => com.google.common.collect.ImmutableMap.of('folderId', 0)).to eq('folders' => { 'folder_id' => 0 })
    end

    it 'normalizes generic keys in object structures' do
      expect(subject.to_structure 'clazz' => nil).to have_key('class')
      expect(subject.to_structure 'idFolder' => nil).to have_key('id_folder')
    end

    it 'normalizes domain specific keys in object structures' do
      expect(subject.to_structure 'EDesk' => nil).to have_key('edesk')
      expect(subject.to_structure 'SkTalk' => nil).to have_key('sktalk')
    end
  end
end
