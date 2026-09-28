# Deterministic, explainable "what next?" recommendations built purely from the
# tool registry — no AI call, no dead recommendations.
#
# The rule: a tool is a valid next step for a finished conversion only if it can
# actually accept that conversion's OUTPUT type. We read the produced file's MIME
# type and return registered tools whose accepted_types include it (excluding the
# tool that just ran and prompt-only AI tools that take no file).
class ToolRecommender
  # A few output types map to a friendlier "family" so, e.g., a produced JPG also
  # surfaces PNG/PDF actions the user is likely to want next.
  def self.for(conversion, limit: 3)
    mime = output_mime(conversion)
    return [] if mime.blank?

    current_id = tool_id_for(conversion.tool_name)

    ToolRegistry.tools.select { |t|
      t[:id] != current_id &&
        t[:input_type] != :prompt &&
        Array(t[:accepted_types]).include?(mime)
    }.first(limit)
  end

  def self.output_mime(conversion)
    return nil unless conversion.output_file.attached?

    type = conversion.output_file.blob.content_type.presence
    return type if type && type != "application/octet-stream"

    # Fall back to extension-based detection when the stored type is generic.
    ext = File.extname(conversion.output_file.blob.filename.to_s)
    Array(Marcel::MimeType.for(name: "x#{ext}")).first
  end

  def self.tool_id_for(class_name)
    ToolRegistry.tools.find { |t| t[:class_name] == class_name }&.dig(:id)
  end
end
