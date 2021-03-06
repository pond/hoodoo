########################################################################
# File::    augmented_array.rb.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of Ruby standard library Array used by the
#           Hoodoo::Client::Endpoint family.
# ----------------------------------------------------------------------
#           11-Dec-2014 (ADH): Created.
#           05-Mar-2015 (ADH): Moved to Hoodoo::Client.
########################################################################

module Hoodoo
  class Client # Just used as a namespace here

    # Base mixin for Hoodoo::Client::AugmentedHash and
    # Hoodoo::Client::AugmentedArray, used by the
    # Hoodoo::Client::Endpoint family for return
    # values in its resource calling API - see:
    #
    # * Hoodoo::Client::Endpoint#list
    # * Hoodoo::Client::Endpoint#show
    # * Hoodoo::Client::Endpoint#create
    # * Hoodoo::Client::Endpoint#update
    # * Hoodoo::Client::Endpoint#delete
    #
    # The error handling mechanism this mixin provides is intentionally
    # analogous to that used for mapping ActiveRecord model validation
    # failures to platform errors in Hoodoo::ActiveRecord::ErrorMapping
    # for when resource endpoint implementations are calling other
    # resource endpoint implementations, while also supporting use cases
    # of external callers wanting to communicate with resources from
    # "outside the system".
    #
    module AugmentedBase

      # This call is typically used by resource endpoint implementations
      # ("service authors") during inter-resource calls, rather than by
      # external entities calling into a system via Hoodoo::Client.
      #
      # Errors set via #set_platform_errors are added to the
      # given Hoodoo::Errors instance. Generally, #set_platform_errors is
      # only called by the Hoodoo::Client under-the-hood implementation
      # code as part of routine error handling.
      #
      # Returns +true+ if any errors were added else +false+ if everything
      # is OK (no platform errors have been noted internally).
      #
      # This makes the idiomatic example for "make inter-resource call,
      # add any errors to my service's response and return on error" very
      # simple, at the expense of modifying the passed-in error collection
      # contents (mutating a parameter is a risky pattern). For an
      # alternative pattern which avoids this, see #platform_errors.
      #
      # Otherwise, a hypothetical resource +Member+ could be listed as
      # follows, as part of a hypothetical +show+ implementation of some
      # other resource:
      #
      #     def show( context )
      #       list = context.resource( :Member ).list()
      #       return if list.adds_errors_to?( context.response.errors )
      #       # ...
      #     end
      #
      # External callers that have nothing to do with resource endpoint
      # implementations could still construct an errors collection manually
      # and make use of this method, but calling #platform_errors makes a
      # lot more sense for that use case.
      #
      # +collection+:: A Hoodoo::Errors instance, typically obtained
      #                from the Hoodoo::Services::Context instance passed to
      #                a service implementation in calls like
      #                Hoodoo::Services::Implementation#list or
      #                Hoodoo::Services::Implementation#show, via
      #                +context.response.errors+
      #                (i.e. Hoodoo::Services::Context#response /
      #                Hoodoo::Services::Response#errors). The collection you
      #                pass is updated with any errors noted internally via
      #                (usually-middleware-automatically-called) method
      #                #set_platform_errors.
      #
      def adds_errors_to?( collection )
        to_add = self.platform_errors()

        if to_add.has_errors?
          collection.merge!( to_add )
          return true
        else
          return false
        end
      end

      # This call is typically used by external entities calling into a
      # system via Hoodoo::Client.
      #
      # Returns a Hoodoo::Errors instance that's either been assigned
      # via #set_platform_errors or is an empty, internally assigned
      # collection. This method is very closely related to
      # #adds_errors_to? and, if you have not already done so, you should
      # read that method's documentation before continuing.
      #
      # For external client users, the error handling pattern is:
      #
      #     client   = Hoodoo::Client.new( ... )
      #     endpoint = client.resource( 'Foo' )
      #     result   = endpoint.show/list/create/update/delete( ... )
      #
      #     if result.platform_errors.halt_processing?
      #       # Handle result.platform_errors's error data
      #     else
      #       # Success case
      #     end
      #
      # For service authors, the #platform_errors method supports a
      # slightly more verbose form of error handling for inter-resource
      # calls that avoids changing a passed in parameter in the manner
      # of #adds_errors_to?. Compare the idiom shown there:
      #
      #     return if list.adds_errors_to?( context.response.errors )
      #
      # ...with the idiomatic use of this method:
      #
      #     context.response.add_errors( list.platform_errors )
      #     return if context.response.halt_processing?
      #
      # It is a little more verbose and very slightly less efficient as
      # it involves more method calls end to end, but you may prefer the
      # conceptually cleaner approach. You can lean on the return value
      # of #add_errors and end up back at one line of (very slightly less
      # obvious) code, too:
      #
      #     return if context.response.add_errors( list.platform_errors )
      #
      def platform_errors
        @nz_co_loyalty_platform_errors ||= Hoodoo::Errors.new
      end

      # Sets the Hoodoo::Errors instance used by #adds_errors_to? or
      # returned by #platform_errors.
      #
      # It is expected that only Hoodoo::Client-family code will call this
      # method as part of general error handling, though client code may
      # find other uses that are independent of the inter-resource call
      # case wherein the method may be safely invoked.
      #
      def set_platform_errors( errors )
        @nz_co_loyalty_platform_errors = errors
      end

      # On success, this Hash may be updated with options describing
      # 'out-of-band' information associated with the response, derived from
      # HTTP headers for HTTP-based transports. Non-HTTP transports still
      # carry HTTP-like headers and apply equally here.
      #
      # For more about the mapping from header to option, see class method
      # Hoodoo::Client::Headers.x_header_to_options. Since Hoodoo itself
      # sets up <tt>X-Interaction-ID</tt> and <tt>X-Service-Response-Time</tt>
      # headers in _most_ cases, you can expect to at least find the options
      # +interaction_id+ and +service_response_time+ set for successful calls.
      #
      # Under some circustances, especially for certain error conditions, the
      # value may be +nil+, though Hoodoo endeavours to avoid this and at
      # least fill in +interaction_id+ where possible.
      #
      attr_accessor :response_options

    end
  end
end
