require File.join(File.dirname(__FILE__), '../test_helper')


class CustomFieldType < Fields::Field
  attr_reader :options
end

describe HammerCLI::Output::Dsl do

  let(:dsl) { HammerCLI::Output::Dsl.new }
  let(:field_type) { FieldType }
  let(:first_field) { dsl.fields[0] }
  let(:last_field) { dsl.fields[-1] }

  it "should be empty after initialization" do
    dsl.fields.length.must_equal 0
  end

  describe "fields" do
    it "should create Field as default field type" do
      dsl.build do
        field :f, "F"
      end
      first_field.class.must_equal Fields::Field
    end

    it "should create field of desired type" do
      dsl.build do
        field :f, "F", CustomFieldType
      end
      first_field.class.must_equal CustomFieldType
    end

    it "should store all field details" do
      dsl.build do
        field :f, "F"
      end

      first_field.must_equal last_field
      first_field.path.must_equal [:f]
      first_field.label.must_equal "F"
    end

    it "can define multiple fields" do
      dsl.build do
        field :name, "Name"
        field :surname, "Surname"
        field :email, "Email"
      end

      dsl.fields.length.must_equal 3
    end
  end

  describe "custom fields" do

    let(:options) {{:a => 1, :b => 2}}

    it "it creates field of a desired type" do
      dsl.build do
        custom_field CustomFieldType, :a => 1, :b => 2
      end
      first_field.class.must_equal CustomFieldType
    end
  end

  describe "path definition" do

    it "from appends to path" do
      dsl.build do
        from :key1 do
          field :email, "Email"
        end
      end
      last_field.path.must_equal [:key1, :email]
    end

    it "path can be nil to handle the parent structure" do
      dsl.build do
        from :key1 do
          field nil, "Email"
        end
      end
      last_field.path.must_equal [:key1]
    end

    it "from can be nested" do
      dsl.build do
        from :key1 do
          from :key2 do
            from :key3 do
              field :name, "Name"
            end
            field :email, "Email"
          end
        end
      end
      first_field.path.must_equal [:key1, :key2, :key3, :name]
      last_field.path.must_equal [:key1, :key2, :email]
    end

  end


  describe "label" do

    it "creates field of type Label" do
      dsl.build do
        label "Label"
      end
      first_field.class.must_equal Fields::Label
    end

    it "allows to define subfields with dsl" do
      dsl.build do
        label "Label" do
          field :a, "A"
          field :b, "B"
        end
      end

      first_field.fields.map(&:label).must_equal ["A", "B"]
    end

    it "sets correct path to subfields" do
      dsl.build do
        from :nest do
          label "Label" do
            field :a, "A"
            field :b, "B"
          end
        end
      end

      first_field.fields.map(&:path).must_equal [[:a], [:b]]
    end

  end


  describe "collection" do

    it "creates field of type Collection" do
      dsl.build do
        collection :f, "F"
      end
      first_field.class.must_equal Fields::Collection
    end

    it "allows to define subfields with dsl" do
      dsl.build do
        collection :nest, "Label" do
          field :a, "A"
          field :b, "B"
        end
      end

      first_field.fields.map(&:label).must_equal ["A", "B"]
    end

    it "sets correct path to subfields" do
      dsl.build do
        collection :nest, "Label" do
          field :a, "A"
          field :b, "B"
        end
      end

      first_field.fields.map(&:path).must_equal [[:a], [:b]]
    end

  end

end

