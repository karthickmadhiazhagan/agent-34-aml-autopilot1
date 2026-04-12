class ApplicationJob < ActiveJob::Base
  # Retry up to 3 times on transient failures (e.g. DB connection blips),
  # with exponential back-off.
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # Discard the job (don't retry) if the record it operates on no longer exists.
  discard_on ActiveJob::DeserializationError
end
