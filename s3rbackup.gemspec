Gem::Specification.new do |s|
  s.name = "s3rbackup"
  s.version = "0.4.2"
  s.date = "2010-02-26"
  s.summary = "Simple backup on Amazon S3"
  s.email = "sacchi.nicola@gmail.com"
  s.homepage = "http://github.com/niky81/s3rbackup"
  s.description = "s3rbackup is a command line program for backing and restore group of directory or file in s3, it ships with integrated database for search in backup data."
  s.has_rdoc = false
  s.authors = ["Nicola Sacchi"]
  s.files = ["LICENSE", "README" , "lib/s3dbsync.rb", "bin/s3query.rb", "bin/s3rbackup.rb", "bin/s3autobackup.rb"]
	s.executables << "s3query.rb"
	s.executables << "s3rbackup.rb"
	s.executables << "s3autobackup.rb"
  s.test_files = []
  s.add_dependency("aws-s3", ["> 0.0.0"])
  s.add_dependency("right_aws", ["> 0.0.0"])
  s.add_dependency("OptionParser", ["> 0.0.0"])
end
