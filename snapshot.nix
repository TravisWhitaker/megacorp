{
  resolver = "lts-24.37";
  extras = hackage:
  {
    packages =
    {
      uhd = hackage."uhd"."0.1.0.1".revisions.default;
      # "vulkan" = hackage."vulkan"."3.26.2".revisions.default;
    };
  };
}
