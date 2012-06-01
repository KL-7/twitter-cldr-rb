# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'spec_helper'

include TwitterCldr::Resources

describe Loader do
  let(:loader) { Loader.new }

  describe '#get_yaml_resource' do
    let(:resource_path) { 'random/resource.yml' }
    let(:resource_content) { 'random YAML content' }

    it 'loads the correct YAML file' do
      stub_resource_file(resource_path) { "---\n- 1\n- 2\n" }
      loader.get_yaml_resource(:random, :resource).should == [1, 2]
    end

    it 'symbolizes hash keys' do
      stub_resource_file(resource_path) { "---\n:a:\n  :b: 3\n" }
      loader.get_yaml_resource(:random, :resource).should == { :a => { :b => 3 } }
    end

    it 'loads the resource only once' do
      mock(loader).load_resource(resource_path).once { resource_content }

      result = loader.get_yaml_resource(:random, :resource)
      result.should == resource_content
      # second time load_resource is not called but we get the same object as before
      loader.get_yaml_resource(:random, :resource).object_id.should == result.object_id
    end

    it 'accepts a variable length resource path both in symbols and strings' do
      stub(loader).load_resource('foo/bar/baz.yml') { 'foo-bar-baz' }
      loader.get_yaml_resource('foo', :bar, 'baz').should == 'foo-bar-baz'
    end

    it 'raises an exception if resource file is missing' do
      mock(File).file?(File.join(TwitterCldr::RESOURCES_DIR, 'foo/bar.yml')) { false }
      lambda { loader.get_yaml_resource(:foo, :bar) }.should raise_error(ArgumentError, "Resource 'foo/bar.yml' not found.")
    end

    context "custom resources" do
      it "doesn't merge the custom resource if it doesn't exist" do
        mock(loader).read_resource_file('foo/bar.yml') { ":foo: bar" }
        loader.get_yaml_resource(:foo, :bar).should == { :foo => "bar" }
      end

      it 'merges the given file with its corresponding custom resource if it exists' do
        mock(loader).read_resource_file('foo/bar.yml') { ":foo: bar" }
        mock(loader).resource_exists?('custom/foo/bar.yml') { true }
        mock(loader).read_resource_file('custom/foo/bar.yml') { ":bar: baz" }

        # make sure load_resource is called with custom = false the second time
        mock.proxy(loader).load_yml_resource("foo/bar.yml")
        mock.proxy(loader).load_yml_resource("custom/foo/bar.yml", false)

        loader.get_yaml_resource(:foo, :bar).should == { :foo => "bar", :bar => "baz" }
      end
    end
  end

  describe '#get_locale_resource' do
    it 'loads the correct locale resource file' do
      stub(loader).get_yaml_resource(:locales, :de, :numbers) { 'foo' }
      loader.get_locale_resource(:de, :numbers).should == 'foo'
    end

    it 'loads the resource only once' do
      mock(loader).load_resource('locales/de/numbers.yml').once { 'foo' }

      result = loader.get_locale_resource(:de, :numbers)
      # second time get_yaml_resource is not called but we get the same object as before
      loader.get_locale_resource(:de, :numbers).object_id.should == result.object_id
    end

    it 'converts locales' do
      mock(TwitterCldr).convert_locale('zh-tw') { :'zh-Hant' }
      mock(loader).get_yaml_resource(:locales, :'zh-Hant', :numbers) { 'foo' }

      loader.get_locale_resource('zh-tw', :numbers).should == 'foo'
    end
  end

  describe '#get_plain_resource' do
    let(:resource_path) { 'pain/text.txt' }
    let(:resource_content) { 'plain-text' }

    it 'loads the correct file by string path' do
      stub_resource_file(resource_path) { resource_content }
      loader.get_plain_resource(resource_path).should == resource_content
    end

    it 'loads the resource only once' do
      mock(loader).load_resource(resource_path).once { resource_content }

      result = loader.get_plain_resource(resource_path)
      result.should == resource_content
      # second time load_resource is not called but we get the same object as before
      loader.get_plain_resource(resource_path).object_id.should == result.object_id
    end

    it 'skips YAML parsing and deep keys symbolization' do
      dont_allow(YAML).load
      dont_allow(TwitterCldr::Utils).deep_symbolize_keys

      stub_resource_file(resource_path) { resource_content }
      loader.get_plain_resource(resource_path).should == resource_content
    end
  end

  def stub_resource_file(resource_path, &block)
    file_path = File.join(TwitterCldr::RESOURCES_DIR, resource_path)
    stub(File).read(file_path, &block)
    stub(File).file?(file_path) { true }
  end

end