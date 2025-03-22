{
  resolver = "lts-23.9";
  extras = hackage:
  {
    packages =
    {
      "vulkan" = hackage."vulkan"."3.26.2".revisions.default;
    };
  };
}
