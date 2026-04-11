{
  resolver = "lts-24.36";
  extras = hackage:
  {
    packages =
    {
      # "vulkan" = hackage."vulkan"."3.26.2".revisions.default;
    };
  };
}
