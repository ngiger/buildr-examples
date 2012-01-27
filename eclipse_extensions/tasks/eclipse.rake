#!/usr/bin/env ruby
# Copyright 2012 by Niklaus Giger <niklaus.giger@member.fsf.org
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Here we define somme common layout/rules to match the written and
# unwritten laws of the various Eclipse developers
# - Adding PDE-Test layout
#
#-----------------------------------------------------------------------------
# Early init
#-----------------------------------------------------------------------------
require 'buildr4osgi'
require 'buildr/bnd'
require 'buildr4osgi/eclipse'

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

module EclipseExtension
  include Extension

  Layout.default[:source, :main, :java]      = 'src'
  Layout.default[:source, :main, :resources] = 'rsc'
  Layout.default[:source, :main, :scala]     = 'src'
  Layout.default[:source, :test, :java]      = 'test'
  Layout.default[:source, :test, :scala]     = 'test'

  before_define do |project|
    if !ENV['OSGi'] 
	puts "OSGi musts point to an installed eclipse"
	exit(3)
    end
    project.compile.dependencies << ENV['OSGi']
    if project.parent
      project.compile.with project.dependencies
      addDependencies(project) if project.dependencies
      project.package(:plugin) if  Dir.glob(File.join(project._,'plugin.xml')) 
      project.compile { FileUtils.makedirs File.join(project.path_to(:target, 'root', 'resources'))
                         FileUtils.makedirs File.join(project._, 'target', 'resources_src', 'resources')
                      }
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

      # Add all internationalization messages
      Dir.glob(File.join(project._('src','**','messages*.properties'))).each { |x|
        project.package(:plugin).include x, :as => /src\/(.*)/.match(x)[1]
      } 

    end
  end

end

class Buildr::Project
  include EclipseExtension
end
