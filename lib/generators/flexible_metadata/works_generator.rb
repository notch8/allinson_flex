# frozen_string_literal: true

class FlexibleMetadata::WorksGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc 'This generator configures works to use FlexibleMetadata.'

  def banner
    say_status("info", "Configuring Works to use FlexibleMetadata", :blue)
  end

  def gather_work_types
    @work_types = FlexibleMetadata::DynamicSchema.all.map { |c| c.flexible_metadata_class }.uniq
    @curation_concerns = Hyrax.config.curation_concerns.map(&:to_s)
    if @work_types.blank?
      say_status("error", "No FlexibleMetadata Classes have been defined. Please load or create a Profile.", :red)
      exit 0
    end
  end

  def generate_works
    @work_types.each do |work_type|
      next if @curation_concerns.include?(work_type)
      say_status("info", "GENERATING #{work_type}", :blue)
      generate "hyrax:work #{work_type}", '-f'
    end
  end

  def configure_actors
    @work_types.each do |work_type|
      file = "app/actors/hyrax/actors/#{work_type.downcase}_actor.rb"
      file_text = File.read(file)
      insert_1 = '      include FlexibleMetadata::DynamicSchemaActorBehavior'
      insert_2 = "      def create(env)\n        super\n      end"
      insert_3 = '        add_dynamic_schema(env)'

      insert_into_file file, after: /Hyrax::Actors::BaseActor/ do
        "\n#{insert_1}"
      end unless file_text.include?(insert_1)

      insert_into_file file, before: /\n    end\n  end\nend/ do
        "\n#{insert_2}"
      end unless file_text.include?('def create(env)')

      insert_into_file file, after: /def create\(env\)/ do
        "\n#{insert_3}"
      end unless file_text.include?(insert_3)
    end
  end

  def configure_controllers
    @work_types.each do |work_type|
      file = "app/controllers/hyrax/#{work_type.pluralize.downcase}_controller.rb"
      file_text = File.read(file)
      insert = '    include FlexibleMetadata::DynamicControllerBehavior'
      next if file_text.include?(insert)
      insert_into_file file, before: /    self.curation_concern_type/ do
        "#{insert}\n"
      end
    end
  end

  # @todo - sometimes all the fields go after the 'Additional Fields' button
  # @todo - contextual form labels
  def configure_forms
    @work_types.each do |work_type|
      file = "app/forms/hyrax/#{work_type.downcase}_form.rb"
      file_text = File.read(file)
      insert = '    include FlexibleMetadata::DynamicFormBehavior'
      next if file_text.include?(insert)
      insert_into_file file, before: /\n  end/ do
        "\n#{insert}"
      end
    end
  end

  def configure_indexers
    @work_types.each do |work_type|
      file = "app/indexers/#{work_type.downcase}_indexer.rb"
      file_text = File.read(file)
      insert = '  include FlexibleMetadata::DynamicIndexerBehavior'
      next if file_text.include?(insert)
      insert_into_file file, before: /\nend/ do
        "#{insert}\n"
      end
    end
  end

  def configure_models
    @work_types.each do |work_type|
      file = "app/models/#{work_type.downcase}.rb"
      file_text = File.read(file)
      insert = '  include FlexibleMetadata::DynamicMetadataBehavior'
      next if file_text.include?(insert)
      insert_into_file file, before: /\nend/ do
        "\n#{insert}"
      end
      gsub_file file, /\n  include ::Hyrax::BasicMetadata/, "\n  # include ::Hyrax::BasicMetadata"
    end
  end

  def configure_solr_document
    file = "app/models/solr_document.rb"
    file_text = File.read(file)
    insert = '  include FlexibleMetadata::DynamicSolrDocument'
    return if file_text.include?(insert)
    insert_into_file file, after: /Hyrax::SolrDocumentBehavior/ do
      "\n#{insert}"
    end
  end

  def configure_presenters
    @work_types.each do |work_type|
      file = "app/presenters/hyrax/#{work_type.downcase}_presenter.rb"
      file_text = File.read(file)
      insert = "    include FlexibleMetadata::DynamicPresenterBehavior\n    self.model_class_name = '#{work_type}'"
      next if file_text.include?(insert)
      insert_into_file file, before: /\n  end\nend/ do
        "\n#{insert}"
      end
    end
  end

  def add_views
    copy_file 'app/views/hyrax/base/_attribute_rows.html.erb', 'app/views/hyrax/base/_attribute_rows.html.erb'
  end

  def display_readme
    readme 'WORKS_README'
  end
end
