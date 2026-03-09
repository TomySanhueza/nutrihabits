class ImagePreflightService
  MAX_SIZE_BYTES = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/heic image/heif].freeze

  def initialize(upload)
    @upload = upload
  end

  def call
    return failure("Debes seleccionar una imagen.") if @upload.blank?
    return failure("El archivo es demasiado grande. Máximo 10 MB.") if file_size > MAX_SIZE_BYTES
    return failure("Formato no soportado.") unless ALLOWED_CONTENT_TYPES.include?(content_type)

    {
      ok: true,
      content_type: content_type,
      byte_size: file_size,
      message: "Imagen válida para análisis."
    }
  end

  private

  def file_size
    @upload.respond_to?(:size) ? @upload.size.to_i : 0
  end

  def content_type
    @upload.respond_to?(:content_type) ? @upload.content_type.to_s : ""
  end

  def failure(message)
    { ok: false, message: message }
  end
end
