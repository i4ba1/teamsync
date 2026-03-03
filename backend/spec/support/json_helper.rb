module JsonHelper
  def json_body
    JSON.parse(response.body, symbolize_names: true)
  end

  def expect_json_keys(keys)
    expect(json_body.keys).to match_array(keys)
  end

  def expect_json_types(types)
    types.each do |key, type|
      value = json_body[key]
      case type
      when :string
        expect(value).to be_a(String)
      when :integer
        expect(value).to be_a(Integer)
      when :boolean
        expect(value).to be_in([true, false])
      when :array
        expect(value).to be_a(Array)
      when :hash
        expect(value).to be_a(Hash)
      when :nil
        expect(value).to be_nil
      end
    end
  end
end
