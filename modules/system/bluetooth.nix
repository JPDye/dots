_:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    # Experimental enables battery reporting for headphones.
    settings.General.Experimental = true;
  };

  services.blueman.enable = true;
}
