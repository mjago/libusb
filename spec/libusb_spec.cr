require "./spec_helper"

describe "error_name" do
  it "returns SUCCESS for error 0" do
    msg = "LIBUSB_ERROR_NO_MEM"
    Usb.error_name(LibUsb::ErrorCode::ERROR_NO_MEM.value).should eq(msg)
    msg = "LIBUSB_SUCCESS / LIBUSB_TRANSFER_COMPLETED"
    Usb.error_name(LibUsb::ErrorCode::SUCCESS.value).should eq(msg)
  end
end

describe "has_capability" do
  it "returns capability" do
    Usb.has_capability?(LibUsb::Capability::HAS_CAPABILITY).should be_true
  end
  it "returns incapability" do
    Usb.has_capability?(-1).should be_false
  end
end

describe "locale" do
  it "sets valid locale" do
    Usb.locale("en").should be_true
    Usb.locale("fr").should be_true
  end
  it "rejects invalid locale" do
    Usb.locale("").should be_false
  end
end

describe "init" do
  it "successfully initialises library" do
    Usb.new.init.should be_true
  end
end

describe "device_list" do
  it "reads the device list" do
    usb = Usb.new
    usb.init
    dev_list = usb.device_list
    dev_list.class.should eq(String)
    (dev_list.size > 0).should be_true
    # usb.exit
  end
end
