class CVModel {
  // Personal Information
  String? name;
  String? email;
  String? phone;
  String? address;
  String? profileImageUrl;

  // Professional Information
  String? summary;

  // Sections
  List<Experience> experiences = [];
  List<Education> education = [];
  List<Certification> certifications = [];
  List<Project> projects = [];
  List<Language> languages = [];
  List<String> skills = [];

  // Links
  String? linkedIn;
  String? github;
  String? website;

  CVModel();

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'personal_info': {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'profile_image': profileImageUrl,
      },
      'professional_info': {
        'summary': summary,
      },
      'experiences': experiences.map((e) => e.toMap()).toList(),
      'education': education.map((e) => e.toMap()).toList(),
      'certifications': certifications.map((e) => e.toMap()).toList(),
      'projects': projects.map((e) => e.toMap()).toList(),
      'languages': languages.map((e) => e.toMap()).toList(),
      'skills': skills,
      'links': {
        'linkedin': linkedIn,
        'github': github,
        'website': website,
      },
    };
  }

  // Create from Firebase data
  static CVModel fromMap(Map<String, dynamic> map) {
    final cv = CVModel();

    // Personal Info
    final personalInfo = map['personal_info'] ?? {};
    cv.name = personalInfo['name'];
    cv.email = personalInfo['email'];
    cv.phone = personalInfo['phone'];
    cv.address = personalInfo['address'];
    cv.profileImageUrl = personalInfo['profile_image'];

    // Professional Info
    final professionalInfo = map['professional_info'] ?? {};
    cv.summary = professionalInfo['summary'];

    // Lists
    cv.experiences = (map['experiences'] as List?)?.map((e) => Experience.fromMap(e)).toList() ?? [];
    cv.education = (map['education'] as List?)?.map((e) => Education.fromMap(e)).toList() ?? [];
    cv.certifications = (map['certifications'] as List?)?.map((e) => Certification.fromMap(e)).toList() ?? [];
    cv.projects = (map['projects'] as List?)?.map((e) => Project.fromMap(e)).toList() ?? [];
    cv.languages = (map['languages'] as List?)?.map((e) => Language.fromMap(e)).toList() ?? [];
    cv.skills = List<String>.from(map['skills'] ?? []);

    // Links
    final links = map['links'] ?? {};
    cv.linkedIn = links['linkedin'];
    cv.github = links['github'];
    cv.website = links['website'];

    return cv;
  }
}

class Experience {
  String? id;
  String? title;
  String? company;
  String? startDate;
  String? endDate;
  String? description;
  bool? currentlyWorking;

  Experience({
    this.id,
    this.title,
    this.company,
    this.startDate,
    this.endDate,
    this.description,
    this.currentlyWorking,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
      'currently_working': currentlyWorking,
    };
  }

  static Experience fromMap(Map<String, dynamic> map) {
    return Experience(
      id: map['id'],
      title: map['title'],
      company: map['company'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      description: map['description'],
      currentlyWorking: map['currently_working'],
    );
  }
}

class Education {
  String? id;
  String? degree;
  String? institution;
  String? fieldOfStudy;
  String? startDate;
  String? endDate;
  String? description;

  Education({
    this.id,
    this.degree,
    this.institution,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'degree': degree,
      'institution': institution,
      'field_of_study': fieldOfStudy,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
    };
  }

  static Education fromMap(Map<String, dynamic> map) {
    return Education(
      id: map['id'],
      degree: map['degree'],
      institution: map['institution'],
      fieldOfStudy: map['field_of_study'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      description: map['description'],
    );
  }
}

class Certification {
  String? id;
  String? name;
  String? organization;
  String? issueDate;
  String? expirationDate;
  String? credentialId;
  String? credentialUrl;

  Certification({
    this.id,
    this.name,
    this.organization,
    this.issueDate,
    this.expirationDate,
    this.credentialId,
    this.credentialUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'organization': organization,
      'issue_date': issueDate,
      'expiration_date': expirationDate,
      'credential_id': credentialId,
      'credential_url': credentialUrl,
    };
  }

  static Certification fromMap(Map<String, dynamic> map) {
    return Certification(
      id: map['id'],
      name: map['name'],
      organization: map['organization'],
      issueDate: map['issue_date'],
      expirationDate: map['expiration_date'],
      credentialId: map['credential_id'],
      credentialUrl: map['credential_url'],
    );
  }
}

class Project {
  String? id;
  String? name;
  String? description;
  List<String>? technologies;
  String? startDate;
  String? endDate;
  String? projectUrl;

  Project({
    this.id,
    this.name,
    this.description,
    this.technologies,
    this.startDate,
    this.endDate,
    this.projectUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'technologies': technologies,
      'start_date': startDate,
      'end_date': endDate,
      'project_url': projectUrl,
    };
  }

  static Project fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      technologies: List<String>.from(map['technologies'] ?? []),
      startDate: map['start_date'],
      endDate: map['end_date'],
      projectUrl: map['project_url'],
    );
  }
}

class Language {
  String? id;
  String? language;
  String? proficiency; // Beginner, Intermediate, Fluent, Native

  Language({
    this.id,
    this.language,
    this.proficiency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language': language,
      'proficiency': proficiency,
    };
  }

  static Language fromMap(Map<String, dynamic> map) {
    return Language(
      id: map['id'],
      language: map['language'],
      proficiency: map['proficiency'],
    );
  }
}