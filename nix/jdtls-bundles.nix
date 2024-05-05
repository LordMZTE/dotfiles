{ pkgs, ... }:
{
  config.packages.jdtls-bundles = pkgs.linkFarm "jdtls-bundles" [
    {
      name = "java-debug.jar";
      path = pkgs.fetchurl {
        url = "https://git.mzte.de/LordMZTE/-/packages/maven/com.microsoft.java-com.microsoft.java.debug.plugin/0.52.0/files/1444";
        hash = "sha256-GjMQkxHVqp2H4dqh8NFW37N7kuBA2RWTIw9BYuyix4w=";
      };
    }
    {
      name = "decompiler-common.jar";
      path = pkgs.fetchurl {
        url = "https://git.mzte.de/LordMZTE/-/packages/maven/dg.jdt.ls.decompiler-dg.jdt.ls.decompiler.common/0.0.3-snapshot/files/1366";
        hash = "sha256-qSgzUPmUtflDWisTG5RIA/UCPuZiOkP9NOI5zFwXC8E=";
      };
    }
    {
      name = "decompiler-procyon.jar";
      path = pkgs.fetchurl {
        url = "https://git.mzte.de/LordMZTE/-/packages/maven/dg.jdt.ls.decompiler-dg.jdt.ls.decompiler.procyon/0.0.3-snapshot/files/1393";
        hash = "sha256-T+zzLbxrXOPW0Y8mnMKPFxAY1P7/VNKfRwOgcO9tnyo=";
      };
    }
    {
      name = "decompiler-fernflower.jar";
      path = pkgs.fetchurl {
        url = "https://git.mzte.de/LordMZTE/-/packages/maven/dg.jdt.ls.decompiler-dg.jdt.ls.decompiler.fernflower/0.0.3-snapshot/files/1384";
        hash = "sha256-0uR8Pq4vBCz/lc8gE5S7IgfN6Axa4LBYarEJ+XbV3xk=";
      };
    }
    {
      name = "decompiler-cfr.jar";
      path = pkgs.fetchurl {
        url = "https://git.mzte.de/LordMZTE/-/packages/maven/dg.jdt.ls.decompiler-dg.jdt.ls.decompiler.cfr/0.0.3-snapshot/files/1375";
        hash = "sha256-dxiKfDFecbXW/lGd5Ncbk1gldS30RhApCVcYYf0GRH0=";
      };
    }
  ];
}
