{
  resolver = "lts-24.32";
  extras = hackage:
  {
    packages =
    {
      # "vulkan" = hackage."vulkan"."3.26.2".revisions.default;
    };
  };
}
