module JSONSerializer

using JSON

function serialize(data)::String
  JSON.json(data)
end

function deserialize(json)
  JSON.parse(json)
end

end