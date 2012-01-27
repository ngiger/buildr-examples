#!/usr/bin/env ruby
# Copyright 2012 by Niklaus Giger <niklaus.giger@member.fsf.org
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Here we define somme common layout/rules to match the written and
# unwritten laws of the various Elexis developers
# - Handles adding/updating Svn/Mercurial repos for local checkout/Jenkins
# - Adding PDE-Test layout
#
#-----------------------------------------------------------------------------
# Early init
#-----------------------------------------------------------------------------
if ARGV.join(' ').index('addSvnRepo') or
   ARGV.join(' ').index('addMercurialRepo') or
   ARGV.join(' ').index('updateAllCheckouts')
  # These steps have to complete before we can build anything
  # therefore include only minimum to speed things up
  require 'buildr'
else
  require 'buildr/scala'
  require 'buildr4osgi'
  require 'buildr4osgi/eclipse/p2'
  require 'antwrap'
  require 'buildrdeb'
  repositories.remote << "http://repo2.maven.org/maven2"
  repositories.remote << "http://mvnrepository.com/maven2"
  require "buildr/bnd"
  repositories.remote << Buildr::Bnd.remote_repository
  repositories.release_to = 'file:///opt/elexis-release'
  ElexisLayout = Layout.new
  ElexisLayout[:source, :main, :java] = 'src'
  ElexisLayout[:source, :main, :resources] = 'rsc'
  ElexisLayout[:source, :main, :scala] = 'src'
  ElexisLayout[:source, :test, :java] = 'test'
  ElexisLayout[:source, :test, :scala] = 'test'
end

#-----------------------------------------------------------------------------
# Generate installer projects
#-----------------------------------------------------------------------------
Hash.new( 'elexis'    => File.join('elexis-base',        'BuildElexis','build.xml'),
	  'medelexis' => File.join('medelexis-trunk', 'BuildMedelexis','build.xml')
          ).each { 
    |name, file|
    next if !File.exists?(file)
    puts "Adding #{name}-installer: #{file}"
    os  = 'linux.x86_64'
    tgt = "#{name}-#{os}-installer"
    Buildr::write File.join(File.dirname(file), 'buildfile'), %(define '#{name} do
    file "#{File.join(Dir.pwd, 'target',tgt)} do
       izPack('#{tgt}', 2, 3) 
    end
  end
)
	  }

#-----------------------------------------------------------------------------
# Stuff for handling repositories
#-----------------------------------------------------------------------------
desc "Add a new mercurial repository via URL, branch" 
task :addMercurialRepo, :url, :branch do 
  |t, args|
    puts "TODO: add mercurial #{args[:url]} #{args[:branch]}"
end

desc "Add a new Subversion repository via URL, branch" 
task :addSvnRepo, :url, :branch do 
  |t, args|
    puts "TODO: add svn #{args[:url]} #{args[:branch]}"
end

desc "Update all (sub) checkout to branch" 
task :updateAllCheckouts, :branch do 
  |t, args|
    puts "TODO: updateAllCheckouts #{args[:branch]}"
end

def addDependencies(project)
  project.dependencies.each{
    |x|
      next if x.class != Buildr::Project
      if x.compile.target
	  project.compile.with project.dependencies, x,  x.compile.target
	  project.eclipse.exclude_libs += [x.compile.target] 
      else
	project.compile.with x if Dir.glob(project._('src')).size > 0
      end
  }
end

module Elexis
  include Extension

  first_time do
    # Define task not specific to any projet.
    puts "Module Elexis handling common tasks"
#    desc 'Count lines of code in current project'
#    Project.local_task('loc')
  end

  before_define do |project|
    # Define the loc task for this particular project.
    if project.parent
      short = project.name.sub(project.parent.name+':','')
      dirs = Dir.glob(File.join(project._, '..', short+'_test')) + # e.g. ch.rgw.utility_test
	     Dir.glob(File.join(project._, '..', short+'test')) + # e.g. at.medevit.elexis.barcode.test/
	     Dir.glob(File.join(project._, 'tests')) # e.g archie
      if dirs.size == 1
	testBase = File.expand_path(dirs[0])
	project.layout[:source, :test, :java] = testBase
	project.layout[:source, :test] = testBase
	libs = Dir.glob(File.join(testBase, '*.jar')) + Dir.glob(File.join(testBase, 'lib','*.jar'))
	if libs.size > 0
	    puts "Patching #{short} with #{libs.size} libraries: #{testBase} "
	    project.test.with libs
	else
	  puts "Patching #{short}: #{testBase}"
	end
      end
      project.compile.with project.dependencies
      addDependencies(project) if project.dependencies
      mfName = File.join(project._,'META-INF', 'MANIFEST.MF')
      if File.exists?(mfName)
	mf = Buildr::Packaging::Java::Manifest.parse(File.read(mfName))
	frag = mf.main['Fragment-Host']
	if frag
	  puts "#{short}: fragment found #{frag.inspect}"
	  project.compile.with project('#{frag}').dependencies # as #{sName} is a fragment"
	  exit 9
	end
      end

      localJars = Dir.glob(File.join(project._,'*.jar')) + Dir.glob(File.join(project._, 'lib', '*.jar')) 
      project.package(:plugin) if  Dir.glob(File.join(project._,'plugin.xml')) 
      project.package(:plugin).include(Dir.glob(File.join(project._,'medelexis.xml')))
      if Dir.glob(File.join(project._,'src')) and localJars.size >0
	project.package(:plugin).include(Dir.glob(File.join(project._,'*.jar')))
	project.package(:plugin).include(Dir.glob(File.join(project._,'lib', '*.jar')), :path=> 'lib')
	if short.eql?('ch.elexis.artikel_ch')
	  project.package(:bundle)
	else
	  project.package(:bundle).tap do |bnd| 
	    bnd['Import-Package'] = '*;resolution:=optional' # avoid error in ch.ngiger.utilties"
	    bnd['Include-Resource'] = "@#{localJars.join(',@')}"
	  end
	end
      end
      project.compile.dependencies << localJars if localJars.size > 0
      # puts project.layout.inspect
      xx = %(
      #<Buildr::Layout:0x235beddd @mapping={
	[:source, :main, :java]=>"src", 
	[:source, :main, :resources]=>"rsc", 
	[:source, :main, :scala]=>"src", 
	[:source, :test, :java]=>"test", 
	[:source, :test, :scala]=>"test", 
	[:target, :main, :classes]=>"target", 
	[:source, :test]=>"source/test", 
	[:source, :test, :resources]=>"source/test/resources", 
	[:target, :doc]=>"target/doc", 
	[:target, :"ch.unibe.iam.scg.archie-1.1.20120118.jar"]=>"target/ch.unibe.iam.scg.archie-1.1.20120118.jar", 
	[:target, :resources_src]=>"target/resources_src", 
	[:target, :resources_src, :resources]=>"target/resources_src/resources", 
	[:target, :root]=>"target/root", 
	[:target, :root, :resources]=>"target/root/resources", 
	[:target, :"elexisAll-ch.unibe.iam.scg.archie-1.1.20120118.jar"]=>"target/elexisAll-ch.unibe.iam.scg.archie-1.1.20120118.jar"}>
*)
      project.compile { FileUtils.makedirs File.join(project.path_to(:target, 'root', 'resources'))
                        #   FileUtils.makedirs File.join(project.path_to(:target, 'resources_src', 'resources')) 
                         FileUtils.makedirs File.join(project._, 'target', 'resources_src', 'resources')
                      }
      # Add all internationalization messages
      Dir.glob(File.join(project._('src','**','messages*.properties'))).each { |x|
        project.package(:plugin).include x, :as => /src\/(.*)/.match(x)[1]
      } 

    end
  end

  after_define do |project|
    # Now that we know all the source directories, add them.
    if project.parent
      short = project.name.sub(project.parent.name+':','')
    end
  end

  # To use this method in your project:
  #   loc path_1, path_2
  def loc(*paths)
    task('loc'=>paths) if false
  end
end

class Buildr::Project
  include Elexis
end
