require 'rails_helper'

RSpec.describe UpvsObjects do
  subject { described_class }

  describe '.to_structure' do
    it 'transforms Java collections to Ruby objects' do
      expect(subject.to_structure(java.util.ArrayList.new)).to be_an_instance_of(Array)
      expect(subject.to_structure(java.util.HashMap.new)).to be_an_instance_of(Hash)
    end

    it 'transforms Java structures to Ruby objects' do
      expect(subject.to_structure('folderIds' => java.util.Arrays.as_list(0, 1, 2))).to eq('folder_ids' => [0, 1, 2])
      expect(subject.to_structure('folders' => com.google.common.collect.ImmutableMap.of('folderId', 0))).to eq('folders' => { 'folder_id' => 0 })
    end
  end
end
