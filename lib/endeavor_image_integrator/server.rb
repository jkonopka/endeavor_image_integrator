require_relative '../../config/environment'
require_relative 'endeavor_image_integrator'

class EndeavorImageIntegratorServer < Servolux::Server

  def initialize(options)
    super('endeavor_image_integrator', {interval: 1}.merge(options))
    self.continue_on_error = true
  end

  def before_starting
  end

  def after_starting
    logger.info 'Running'
  end

  def before_stopping
    logger.info "Stopping"
    #Thread.pass  # Allow the server thread to wind down
    ::EndeavorImageIntegrator::Worker.stop
  end

  def after_stopping
    logger.info 'Stopped'
  end

  def run
    # This is where you put your main code (which should call into some real
    # implementation)
    ::EndeavorImageIntegrator::Worker.start({:all => true})
  rescue Interrupt, SystemExit, SignalException
    # Ignore
  rescue StandardError => e
    if logger.respond_to? :exception
      logger.exception(e)
    else
      logger.error(e.inspect)
      logger.error(e.backtrace.join("\n"))
    end
  end

end