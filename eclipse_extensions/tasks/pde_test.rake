#!/usr/bin/env ruby

module PDE_test
  include Extension

  first_time do
    # Define task not specific to any projet.
    desc 'Run PDE-tests for the project. Envronment variabls OSGi must point to an empty Eclipse installation!'
    Project.local_task('pde_test')
  end

  before_define do |project|
    if project.parent == nil
      puts "Add PDE_test integration stuff for root project"
      PDE_test::stuffForRootProject 
    else
      # patch directory layout for tests. But leave the use the choice
      # whether he wants to run traditional JUnit tests or our PDE_tests
      short = project.name.sub(project.parent.name+':','')
      dirs = Dir.glob(File.join(project._, '..', short+'-test')) 
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
    end
  end

private 
  ANT_ARTIFACTS = [
    'ant:ant-optional:jar:1.5.3-1',
    'org.apache.ant:ant:jar:1.8.2',
    'org.apache.ant:ant-junit:jar:1.8.2',
    'junit:junit:jar:3.8.2',
    'org.eclipse.jdt:junit:jar:3.3.0-v20070606-0010'
  ]

  def PDE_test::stuffForRootProject
    @@pluginPath  = File.join(ENV['OSGi'], 'plugins') if ENV['OSGi']
    @@pdeTestUtilsJar = File.join('target', 'pde.test.utils','pde.test.utils.jar')
    puts "define pdtest jar #{@@pdeTestUtilsJar}"
    pdeTestSources  = Dir.glob(File.join('pde.test.utils', '*.java'))
    file @@pdeTestUtilsJar => pdeTestSources do
      Buildr.ant('create_eclipse_plugin') do |x|
	FileUtils.makedirs( File.dirname(@@pdeTestUtilsJar))
	x.javac(:srcdir => File.join('pde.test.utils'),
	      :classpath => getPdeTestClasspath.join(File::PATH_SEPARATOR),
	      :includeantruntime => false,
	      :destdir =>  File.dirname(@@pdeTestUtilsJar)
	    )
	x.echo(:message => "Create #{@@pdeTestUtilsJar}")
	x.zip(:destfile => @@pdeTestUtilsJar,
	      :basedir  => File.dirname(@@pdeTestUtilsJar),
	      :includes => '**/*.class')
      end
    end
  end

  # return all needed Eclipse plug-ins for the pdeTestLocator
  def PDE_test::getPdeTestClasspath
    pdeTestPath = []
    pdeTestPath << @@pdeTestUtilsJar if @@pdeTestUtilsJar
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.core.runtime_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.equinox.common_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.ui.workbench_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.jface_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.swt_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, "org.eclipse.swt.gtk.linux*.jar")).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.junit_4*','**','junit.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.apache.ant_*','**','ant.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.apache.ant_*','**','ant-junit.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.jdt.junit_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.debug.core_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.osgi_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.jdt.junit.core_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.core.resources_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath << Dir.glob(File.join(@@pluginPath, 'org.eclipse.equinox.preferences_*.jar')).join(File::PATH_SEPARATOR)
    pdeTestPath
  end

  task :createPDEtestHtml do
    Buildr.ant('create_html') do |ant|      
      FileUtils.makedirs('reports')
      ant.echo(:message => "Generating html report for all PDE tests")
      ant.taskdef :name=>'junitreport', :classname=>'org.apache.tools.ant.taskdefs.optional.junit.XMLResultAggregator',
	      :classpath=>Buildr.artifacts(JUnit.ant_taskdef).each(&:invoke).map(&:to_s).join(File::PATH_SEPARATOR)
      ant.junitreport(:todir => 'reports') do
	  ant.fileset(:dir=>Dir.pwd) { ant.include :name=>'TEST-*.xml' }
	  ant.report(:format => 'frames',  :todir => File.join('reports', 'PDE_test'))
      end
    end
  end
  
  def PDE_test::addTestJar(shortName, project)
    # we need a test fragment for the test
    testClassesDir = project.path_to(:target,:test,:classes)
    testMetaMf = [testClassesDir,'META-INF','MANIFEST.MF'].join(File::SEPARATOR) 
    file testMetaMf do
      Buildr.write testMetaMf, <<EOF
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-Name: #{shortName}_test Fragment
Bundle-SymbolicName: #{shortName}_test
Bundle-Version: #{project.version}
Fragment-Host: #{shortName};bundle-version="#{project.version}"
Bundle-Localization: plugin
Require-Bundle: org.junit
Bundle-RequiredExecutionEnvironment: JavaSE-1.6
EOF
    end

    # we need a jar file with test-fragment classes & manifest
    testFragmentJar = [testClassesDir,"#{shortName}-test_#{project.version}.jar"].join(File::SEPARATOR)
    file testFragmentJar => [testMetaMf, project.test.compile] do
      Buildr.ant('create_eclipse_plugin') do |x|
	x.echo(:message => "Generating test fragment for #{shortName} #{testFragmentJar}")
	x.zip(:destfile => testFragmentJar,
	      :basedir  => testClassesDir,
	      :includes => '**/*.class,META-INF/MANIFEST.MF')
      end
    end
    testFragmentJar.to_s
  end

public
  # you must call run_pde_test from your project. I have no clue
  # where you want junit or pde-tests
  # opts are optional paramaters to be passed to the PDE test
  def PDE_test::run_pde_test(project, classnames = nil, opts = nil)
    project.test.exclude '*' # Tell junit to ignore all JUnit-test, as it would interfere with the PDE test
    # Define the loc task for this particular project.
    tstPath = project.path_to(:source, :test, :java)
    found = Dir.glob(File.join(tstPath, '**', 'AllTests.java'))
    project.PDETestClassName = nil
    if found.size > 0
      # Set java classname 
      project.PDETestClassName = found[0].sub(tstPath,'').gsub(File::SEPARATOR,'.').sub('.src.','').sub(/^\./,'').sub(/\.java$/,'')
      puts "#{project.id} has PDE_test #{project.PDETestClassName}"
    end
    project.PDETestClassName = classnames if classnames
    project.integration.teardown(:createPDEtestHtml) 
    project.integration.prerequisites << @@pdeTestUtilsJar
    project.test.compile.with project.dependencies + project.compile.dependencies
    project.test.with project.compile.target if project.compile.target
    project.test.compile.with ANT_ARTIFACTS
    shortName = project.name.to_s.sub(project.parent.to_s+':','')
    testFragmentJar = PDE_test::addTestJar(shortName, project)
    project.test.using :integration
    project.test.compile.with project.compile.dependencies 
    project.test.compile.with project.package(:jar)
    project.PDETestResultXML = "TEST-#{shortName}.xml"

    pdeJars = [@@pdeTestUtilsJar, project.package(:plugin), testFragmentJar] 
    deps = []
    project.dependencies.each{
      |x|
	next if x.class != Buildr::Project
	pdeJars << x.package(:plugin).to_s if x.package(:plugin)
	deps << x.name
    }
    testPortFileName = 'pde_test_port.properties'
    project.clean.enhance do  FileUtils.rm_f(project.PDETestResultXML) end
    project.integration.prerequisites << project.PDETestResultXML
    file project.PDETestResultXML => pdeJars do
      pdeJars.each { 
	|jar|
	  dest = File.join(@@pluginPath, File.basename(jar.to_s))
	  file dest => jar.to_s do
	    FileUtils.cp(jar.to_s, @@pluginPath, :verbose => true)
	  end
	  file testPortFileName => dest
	  FileUtils.cp(jar.to_s, @@pluginPath, :verbose => true)
      } 
      Java::Commands.java('pde.test.utils.PDETestPortLocator', {:classpath => getPdeTestClasspath } )
      myTestPort = IO.readlines(testPortFileName).to_s.split('=')[1]
      output =[ Dir.pwd, 'reports'].join(File::SEPARATOR)
      Thread.new do
	puts "#{shortName}: Starting PDE-integration test at #{Time.now} (ResultsCollector)"
	res = Java::Commands.java('pde.test.utils.PDETestResultsCollector', shortName, myTestPort, 
				  {:classpath => getPdeTestClasspath} )
	puts "#{shortName}: Finished PDE-integration test at #{Time.now} (ResultsCollector)"
      end
      puts "#{shortName}: Started PDETestResultsCollector. Wait 1 second"; sleep(1)    
      Java::Commands.java('org.eclipse.equinox.launcher.Main', 
			  '-application',    'org.eclipse.pde.junit.runtime.uitestapplication',
			  '-data',           output,
			  '-dev',            'bin',
			  '-clean',
			  '-port',           myTestPort,
			  '-testpluginname', shortName,
			  '-classnames',     project.PDETestClassName,
			  opts,
			  {:classpath =>     Dir.glob(File.join(@@pluginPath,'org.eclipse.equinox.launcher_*.jar'))} 
			  )
      raise "#{project.PDETestResultXML} should exist" if !File.exists?(project.PDETestResultXML)
      raise "#{project.PDETestResultXML} should match succes" if !/<testsuite errors="0" failures="0"/.match(File.read(project.PDETestResultXML))
      # Cleanup things
      FileUtils.rm(testPortFileName, :verbose => false)
      puts "#{shortName}: Finished PDE-integration test at #{Time.now}"
      pdeJars.each{|x|  FileUtils.rm_f(File.join(@@pluginPath, File.basename(x.to_s)), :verbose => true)}
      sleep(1)
    end
    
    # TODO: mv all Text*.xml into a separate directory
    # FileUtils.mv('TEST*.xml', 'reports', :verbose => false)
  end

end

class Buildr::Project
  include PDE_test
  attr_accessor :PDETestClassName,:PDETestResultXML
end
