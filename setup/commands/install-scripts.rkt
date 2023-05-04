#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (define-logging mklink
    (λ (from to)
      (with-handlers ([exn:fail? (const #f)]) (delete-file to))
      (make-file-or-directory-link (normalize-path from) to)))

  (define-logging install-zig-script
    (λ (path)
      (parameterize ([current-directory path] [log-calls #f])
        (cmd "zig" "build" "-p" (output-bin-path) "-Doptimize=ReleaseFast"))))

  ;; Symlink interpreted scripts
  (mklink "scripts/map-touch-display.rkt" (build-path (output-bin-path) "bin" "map-touch-display"))
  (mklink "scripts/playvid.rkt" (build-path (output-bin-path) "bin" "playvid"))
  (mklink "scripts/start-joshuto.sh" (build-path (output-bin-path) "bin" "start-joshuto"))
  (mklink "scripts/startriver.sh" (build-path (output-bin-path) "bin" "startriver"))
  (mklink "scripts/update-nvim-plugins.rkt"
          (build-path (output-bin-path) "bin" "update-nvim-plugins"))
  (mklink "scripts/withjava.sh" (build-path (output-bin-path) "bin" "withjava"))

  ;; Compile Zig scripts
  (install-zig-script "scripts/mzteinit")
  (install-zig-script "scripts/openbrowser")
  (install-zig-script "scripts/playtwitch")
  (install-zig-script "scripts/prompt")
  (install-zig-script "scripts/randomwallpaper")
  (install-zig-script "scripts/vinput")
  null)
