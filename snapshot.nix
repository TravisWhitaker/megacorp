{
  resolver = "lts-24.10";
  extras = hackage:
  {
    packages =
    {
      "vulkan" = hackage."vulkan"."3.26.2".revisions.default;
    };
  };
}
