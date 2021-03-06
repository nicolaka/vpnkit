 module type CONN = sig
   type fd

   val read: fd -> Cstruct.t -> unit Lwt.t
   (** Completely fills the given buffer with data from [fd] *)

   val write: fd -> Cstruct.t -> unit Lwt.t
   (** Completely writes the contents of the buffer to [fd] *)

   val close: fd -> unit Lwt.t
 end

module type VMNET = sig
  (** A virtual ethernet link to the VM *)

  include V1_LWT.NETWORK

  val add_listener: t -> (Cstruct.t -> unit Lwt.t) -> unit
  (** Add a callback which will be invoked in parallel with all received packets *)

  type fd

  val of_fd: client_macaddr:Macaddr.t -> server_macaddr:Macaddr.t
    -> fd -> [ `Ok of t | `Error of [ `Msg of string]] Lwt.t

  val start_capture: t -> ?size_limit:int64 -> string -> unit Lwt.t

  val stop_capture: t -> unit Lwt.t
end

module type TCPIP = sig
  (** A TCP/IP stack *)

  include V1_LWT.STACKV4

  module TCPV4_half_close : Mirage_flow_s.SHUTDOWNABLE
    with type flow = TCPV4.flow
end

module type RESOLV_CONF = sig
  (** The system DNS configuration *)

  val get : unit -> (Ipaddr.t * int) list Lwt.t
end


module type Connector = sig
  (** Make connections into the VM *)

  module Port: sig
    type t
    (** A protocol-specific port id, e.g. a virtio-vsock int32 *)

    val of_string: string -> (t, [> `Msg of string]) Result.result
    val to_string: t -> string
  end

  val connect: Port.t -> Lwt_unix.file_descr Lwt.t
  (** Connect to the given port on the VM *)
end

module type Binder = sig
  (** Bind local ports *)

  val bind: Ipaddr.V4.t -> int -> bool -> (Lwt_unix.file_descr, [> `Msg of string]) Result.result Lwt.t
  (** [bind local_ip local_port stream] binds [local_ip:local_port] with
      either a SOCK_STREAM if [stream] is true, or SOCK_DGRAM otherwise *)
end
