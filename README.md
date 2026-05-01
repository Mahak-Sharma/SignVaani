# SignVaani
## IDEATE

# PROBLEM STATEMENT
The absence of inclusive educational resources makes it challenging for deaf and hard-of-hearing students to continue their studies smoothly.

# DESCRIPTION
The absence of inclusive educational resources creates significant barriers for deaf and hard-of-hearing students in mainstream learning environments. Most classrooms depend heavily on spoken instruction, audio-based materials, and verbal interaction, often without adequate sign language interpretation, captioning, or visually adapted content. This makes it difficult for students to access information in real time, follow discussions, and fully engage with the curriculum alongside their peers.

Over time, these accessibility gaps affect not only academic performance but also confidence, independence, and continuity in education. Without consistent support systems and affordable assistive technologies, students may feel isolated or left behind, increasing the risk of disengagement. Ensuring inclusive, accessible learning resources is essential to help deaf and hard-of-hearing students continue their education smoothly and equally.

# WHY EXISTING SOLUTIONS DON’T WORK?
Existing solutions to support deaf and hard-of-hearing students include:
* Sign language interpreters in classrooms
* Closed captions for videos h
* Hearing aids and cochlear implants 
* Speech-to-text applications 
* Special schools dedicated to deaf education.

However, these solutions often fall short for several reasons. 
* Sign language interpreters are not always available, especially in rural or underfunded Institutions, and hiring them consistently can be expensive. 
* Captions may be inaccurate or delayed, particularly with technical or fast-paced lectures. 
* Assistive devices like hearing aids do not restore full hearing and may not work effectively in noisy classroom environments. 
* Special schools, while supportive, can limit integration into mainstream education. 

As a result, many existing solutions are either inconsistent, costly, inaccessible at scale, or not fully inclusive in real-world classroom settings.

There are many apps that are created for the deaf, but most of them focus either on teaching Indian Sign Language or hiring interpreters. Majority of the apps are focused on ASL, BSL, and other foreign sign languages, but for ISL there are less applications, and therefore, less support.

---

## RESEARCH

# HOW DID WE ARRIVE HERE?
Being a part of the iOS Development Center, powered by Apple and Infosys in our university, it was our goal as a team to not just build a solution for a problem but to ensure that the experience of the user remains at top priority and to bring inclusivity as a consistent and uncompromised virtue.
We all, as a team tried to keep our focus on identifying problems and struggles faced by students, as us being students, we can identify and work on those issues proactively. As we were remembering our own experiences, one incident highlighted the way to our problem statement. There was of a deaf student in one of our team mates school, who used hearing aids in class, yet still struggled to keep up with his studies. This made all of us think and pause about the hardships of students who are deaf or hard-of-hearing, and what problems they face on a daily basis.

To research and enquire more on this, we visited The Bajaj Institute of Learning for the Deaf, Asthal Village, Dehradun. We all interacted with the students there, along with the instructors and met the Principal of the school as well. We attended their classes and events and directly experienced what it meant to be a part of their world. Our questions were asked one by one, and we got more than what we wanted as our answers for validation.
![These are the Photographs taken by us from our visit at the Bajaj Institute of Learning for the Deaf](BIoLftD1.jpeg,BIoLftD2.jpeg,BIoLftD3.jpeg,BIoLftD4.jpeg)

---

## PLANNING

# HOW WE INTEND TO SOLVE?
We intend to solve this problem by developing an accessible, technology-driven solution that ensures deaf and hard-of-hearing students can understand educational content anytime. The application will convert uploaded videos by the user, either from their Photos gallery or by pasting the YouTube link of the video he wants to watch—into a 3D Avatar translating the spoken content into Indian Sign Language, along with the captions synced with the video.

Unlike existing solutions that are costly, inconsistent, or limited to certain institutions, this approach focuses on affordability, portability, and ease of use. Students will be able to access educational content through a iOS device, specifically for iPhones, ensuring they can follow lessons anytime the user wants. By combining 3D avatar transcription integration and captions as the visual support in one unified system, we aim to create a more inclusive learning environment that enables smooth educational continuity.
[This is our keynote](docs/Team_S.pdf)

---

## DESIGN AND PROTOTYPING

Sketched initial ideas and user flows on pen and paper to explore layout concepts.  
Identified feature placement and ensured accessibility-focused structure.  
Designed wireframes and UI screens in [Figma](https://www.figma.com/design/lMto6YkQ5jP5xSOgl4kVzZ/ISL?node-id=428-3859&t=VgfT34hy8PcKKg8A-1)  
Created interactive prototypes to simulate real user navigation.  
Iterated through multiple drafts to refine clarity, typography, and spacing.  
Improved usability and inclusivity before moving to development.

---

## DEVELOPMENT

### FRONTEND
We developed the frontend UI of our application by UIKit of the iOS framework.  
AVPlayer is also used for the side by side viewing of the video and the avatar along with the captions.  
WKWebView is used to showcase the Avatar by using three.js implementation.

---

### BACKEND

#### TRANSCRIPT AND GLOSS
Audio from the uploaded video by the user, will be converted into text, which is the transcript of the video and will be used as captions.  
For this we have used AVFoundation and SFSpeechRecognizer from the Apple Speech Framework.  
Now to implement the ISL Signs on our avatar, we created a gloss dictionary, by using NLP provided by Apple framework.  
These gloss words will be then mapped with our dataset via indexing and will be implemented on our avatar.

---

### AVATAR IMPLEMENTATION
We implemented the 3D Avatar firstly by using the SceneKit, in the iOS framework, which is now deprecated. [You can read the Apple documentation for SceneKit here.](https://developer.apple.com/documentation/scenekit/)  
So we switched to Vision Framework and RealityKit and did our research and implemented the 3D avatar by it.  
Since Vision Framework has 3D points for body pose only and not for hand, we had to switch again, to MediaPipe Holistic.
Now when we were implemenenting with MediaPipe Holistic and RealityKit, there was compatibility issue because of coordinates, so we switched to Three.js.
We are currently using three.js and MediaPipe Holisitc for the direct implementation of the 3d avatar.
