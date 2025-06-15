(in-package "X")

(defmethod irtviewer
  (:create
   (&rest args
	  &key (title "IRT viewer")
	  (view-name (gensym "title"))
	  (hither 200.0) (yon 50000.0)
	  (width 500) (height 500)
          ((:draw-origin do) 150) ((:draw-floor df) nil) ((:floor-color fc) #f(1 1 1))
          (call-super t)
	  &allow-other-keys)
   (let ()
     (setq left-right-angle 60
	   up-down-angle 20
	   viewpoint (float-vector 700 400 250)
	   viewtarget (float-vector 0 0 0)
           draw-origin do draw-floor df floor-color fc
           logging-flag nil)
     (if call-super
         (send-super* :create :width width :height height :title title
                      :event-mask '(:configure) args))
     (setq gl::*perspective-far* yon)
     (setq gl::*perspective-near* hither)
     (setq viewer (apply #'user::view :parent self
			 :x 0 :y 0
			 :width width :height height
			 :title title
			 :name view-name
			 args))
     (setf (get viewer :pickviewer) self)
     (setq user::*viewer* viewer)

     (let ((default-ambient (float-vector 0.1 0.1 0.1 1.0))
           (default-diffuse (float-vector 1.0 1.0 1.0 1.0))
           (default-specular (float-vector 0.1 0.1 0.1 1.0))
           (scale-light0 0.5)
           (scale-light1 0.4)
           (scale-light2 0.2)
           (scale-light3 0.25)
           ;; (scale-light0 1.00)
           ;; (scale-light1 0.70)
           ;; (scale-light2 0.40)
           ;; (scale-light3 0.25)
           )
       (setq gl::*light0* ;; from back
             (instance gl::lightsource :create 0
                       :ambient (scale scale-light0 default-ambient)
                       :diffuse (scale scale-light0 default-diffuse)
                       :specular (scale scale-light0 default-specular)
                       :position (float-vector 4000.0 3000.0 0.0 0.0)))
       (setq gl::*light1* ;; from front-left
             (instance gl::lightsource :create 1
                       :ambient (scale scale-light1 default-ambient)
                       :diffuse (scale scale-light1 default-diffuse)
                       :specular (scale scale-light1 default-specular)
                       :position (float-vector -4000.0 -2000.0 -2000.0 0.0)))
       (setq gl::*light2* ;; from front-left
             (instance gl::lightsource :create 2
                       :ambient (scale scale-light2 default-ambient)
                       :diffuse (scale scale-light2 default-diffuse)
                       :specular (scale scale-light2 default-specular)
                       :position (float-vector -2000.0 -2000.0 2500.0 0.0)))
       (setq gl::*light3*
             (instance gl::lightsource :create 3
                       :ambient (scale scale-light3 default-ambient)
                       :diffuse (scale scale-light3 default-diffuse)
                       :specular (scale scale-light3 default-specular)
                       :position (float-vector 0.0 0.0 0.0 1.0)))
       )
     (send gl::*light0* :opengl)
     (send gl::*light1* :opengl)
     (send gl::*light2* :opengl)
     (send gl::*light3* :opengl)
     ;;
     (send viewer :viewsurface :set-event-proc
	   :buttonrelease-left :draw-event self)
     (send viewer :viewsurface :set-event-proc
	   :buttonpress :set-cursor-pos-event self)
     (send viewer :viewsurface :set-event-proc
	   :motionnotify-left :move-coords-event self)
     (send viewer :viewsurface :set-event-proc
	   :motionnotify-middle :move-coords-event self)

     (send self :look1)
     (send self :draw-objects)
     self)))

(in-package "USER")
