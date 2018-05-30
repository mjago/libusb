@[Link("usb-1.0")]
lib LibUsb
  MUTEX_SIZE =
    if LINUX && __LP64__
      40
    elsif LINUX
      24
    elsif DARWIN
      44
    else
      raise "Error: can't set MUTEX_SIZE!"
    end

  enum ErrorCode
    ERROR_OTHER         = -99
    ERROR_NOT_SUPPORTED = -12
    ERROR_NO_MEM
    ERROR_INTERRUPTED
    ERROR_PIPE
    ERROR_OVERFLOW
    ERROR_TIMEOUT
    ERROR_BUSY
    ERROR_NOT_FOUND
    ERROR_NO_DEVICE
    ERROR_ACCESS
    ERROR_INVALID_PARAM
    ERROR_IO
    SUCCESS
    TRANSFER_COMPLETED  = 0
    TRANSFER_ERROR
    TRANSFER_TIMED_OUT
    TRANSFER_CANCELLED
    TRANSFER_STALL
    TRANSFER_NO_DEVICE
    TRANSFER_OVERFLOW
  end

  enum Capability
    HAS_CAPABILITY                = 0x0000
    HAS_HOTPLUG                   = 0x0001
    HAS_HID_ACCESS                = 0x0100
    SUPPORTS_DETACH_KERNEL_DRIVER = 0x0101
  end

  alias DeviceHandle = Void*
  alias Context = Void*
  alias UsbSpeed = Void*
  alias Mutex = Void*
  alias Device = Void*

  struct Descriptor
    bLength : UInt8
    # Size of this descriptor (in bytes)
    bDescriptorType : UInt8
    # Descriptor type. More...
    bcdUSB : UInt16
    # USB specification release number in binary-coded decimal. More...
    bDeviceClass : UInt8
    # USB-IF class code for the device. More...
    bDeviceSubClass : UInt8
    # USB-IF subclass code for the device, qualified by the bDeviceClass value.
    bDeviceProtocol : UInt8
    # USB-IF protocol code for the device, qualified by the bDeviceClass and bDeviceSubClass values.
    bMaxPacketSize0 : UInt8
    # Maximum packet size for endpoint 0.
    idVendor : UInt16
    # USB-IF vendor ID.
    idProduct : UInt16
    # USB-IF product ID.
    bcdDevice : UInt16
    # Device release number in binary-coded decimal.
    iManufacturer : UInt8
    # Index of string descriptor describing manufacturer.
    iProduct : UInt8
    # Index of string descriptor describing product.
    iSerialNumber : UInt8
    # Index of string descriptor containing device serial number.
    bNumConfigurations : UInt8
    # Number of possible configurations.
  end

  fun error_name = libusb_error_name(err : Int32) : UInt8*
  fun has_capability = libusb_has_capability(capability : UInt32) : Int32
  fun setlocale = libusb_setlocale(UInt8*) : Int32
  fun init = libusb_init : Int32
  fun device_list = libusb_get_device_list(Void*, Device) : Int32
  fun device_descriptor = libusb_get_device_descriptor(Void*, Descriptor*) : Int32
  fun bus_number = libusb_get_bus_number(Void*) : Int32
  fun device_address = libusb_get_device_address(Void*) : Int32
  fun port_numbers = libusb_get_port_numbers(Void*, Void*, Int32) : Int32
  fun exit = libusb_exit(ctx : Context)
end

class Usb
  @context : Void* = Pointer(Void).malloc(1024 * 16)
  @context_ptr : Void** = pointerof(@context)
  @descriptor : Void* = Pointer(Void).malloc(1024 * 16)
  @descriptor_ptr : Void** = pointerof(@descriptor)
  @device : Void* = Pointer(Void).malloc(1024 * 256)
  @device_ptr : Void** = pointerof(@device)
  SUCCESS = LibUsb::ErrorCode::SUCCESS.value

  def self.error_name(err)
    String.new(LibUsb.error_name(err))
  end

  def self.has_capability?(cap)
    return true if LibUsb.has_capability(cap) == 1
    false
  end

  def self.locale(str : String)
    res = LibUsb.setlocale(str.to_slice)
    res == SUCCESS ? true : false
  end

  def init
    res = LibUsb.init
    res == 0 ? true : false
  end

  def device_list
    res = LibUsb.device_list(Pointer(Void).null.as(Void*), pointerof(@device_ptr))
    raise "Error: Failed to get device list!" if (res < 0)
    sprint_devs res, pointerof(@device_ptr)
  end

  def exit
    LibUsb.exit(@context)
  end

  private def sprint_devs(count, devs)
    str = ""
    path = Pointer(UInt8).malloc(8)
    dev_count = "#{count} devices in device list!\n"
    0.upto(count - 1) do |x|
      desc = LibUsb::Descriptor.new
      res = LibUsb.device_descriptor(devs.value[x], pointerof(desc))
      raise "Error: Couldn't get device descriptor" if res < 0
      bus_num = LibUsb.bus_number(devs.value[x])
      dev_addr = LibUsb.device_address(devs.value[x])
      res = LibUsb.port_numbers(devs.value[x], path, 8)

      str = String.build do |str|
        str << "%04x " % desc.idVendor
        str << ":"
        str << "%04x" % desc.idProduct
        str << " (bus "
        str << bus_num
        str << ", device "
        str << dev_addr
        str << ")"
        if (res > 0)
          str << " path: %d" % path[0]
          1.upto(res - 1) do |x|
            str << ".%d" % path[x]
          end
        end
      end
    end
    dev_count + str
  end
end
