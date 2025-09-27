{
  resolver = "nightly-2025-09-25";
  extras = hackage:
  {
    packages =
    {
      "vulkan" = hackage."vulkan"."3.26.2".revisions.default;
    };
  };
}
