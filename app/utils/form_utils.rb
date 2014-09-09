module FormUtils
  module_function

  # Define a form class that can be used with ActiveSupport form bindings
  #
  # Usage:
  #
  # -- in some_controller.rb --
  #
  # MyForm = Util::FormUtils.define_form("MyForm", :name, :password)
  #   .with_validations { validates_presence_of :name }
  #
  # def new
  #   render locals: { form_obj: MyForm.new }
  # end
  #
  # def create
  #   myForm = MyForm.new(params[:my_form])
  #   if myForm.valid?
  #     ...
  #
  def define_form(form_name, *ks)
    Class.new(Object) { |klass|
      include ActiveModel::Validations
      include ActiveModel::Conversion

      @__keys = ks
      @__form_name = form_name
      @__validation_blocks = []

      def self.keys
        @__keys
      end

      def self.validation_blocks
        @__validation_blocks
      end

      attr_reader(*ks)

      def initialize(opts = {})
        self.class.keys.each { |k|
          instance_variable_set("@#{k.to_s}", opts[k]) unless opts[k].nil?
        }
      end

      def persisted?
        false
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, @__form_name)
      end

      def self.with_validations(&block)
        @__validation_blocks << block
        class_exec(&block)
        self
      end
    }
  end

  def merge(form_name, *form_classes)
    keys = form_classes.map(&:keys).flatten
    validation_blocks = form_classes.map(&:validation_blocks).flatten

    form = FormUtils.define_form(form_name, *keys)

    validation_blocks.each do |block|
      form.with_validations(&block)
    end

    form
  end
