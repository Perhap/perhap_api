defmodule API.Error do
  @enforce_keys [:http_code, :code, :message]
  defstruct [:http_code, :code, :message]

  @type t :: %API.Error {
    http_code: String.t,
    code:      String.t,
    message:   String.t
  }

  # @spec build_error(String.t, String.t, String.t) :: API.Error.t
  defp build_error(http_code, code, message) do
    %API.Error{http_code: http_code, code: code, message: message}
  end

  @spec make(atom) :: API.Error.t
  def make(:invalid_event_id) do
    build_error(400,
        "InvalidEventId",
        "V1 UUID Required")
  end

  @spec make(atom) :: API.Error.t
  def make(:validation) do
    build_error(400,
        "ValidationError",
        "One or more required parameter values were missing.")
  end

  @spec make(atom) :: API.Error.t
  def make(:not_found) do
    build_error(404,
        "NotFound",
        "Resource Not Found")
  end

  @spec make(atom) :: API.Error.t
  def make(:model_not_implemented) do
    build_error(500,
        "InternalServerError",
        "Model Not Implemented.")
  end

  @spec make(atom) :: API.Error.t
  def make(:operation_not_implemented) do
    build_error(500,
        "InternalServerError",
        "Operation Not Implemented.")
  end

  @spec make(atom) :: API.Error.t
  def make(:service_unavailable) do
    build_error(503,
        "ServiceUnavailable",
        "Please try again later.")
  end

  @spec format(atom) :: iodata
  def format(atom) when is_atom(atom) do
    error = make(atom)
    Poison.encode!(%{
      type: error.code,
      message: error.message})
  end

  @spec format(API.Error.t) :: iodata
  def format(%API.Error{} = error) do
    %{type: error.code,
      message: error.message}
  end
end