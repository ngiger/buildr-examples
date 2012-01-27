#!/usr/bin/env ruby
puts "I'am in #{__FILE__}"
module PDE_test
  include Extension

  first_time do
    # Define task not specific to any projet.
    desc 'Run PDE-tests for the project (environment variable EclipseTarFile must be defined. Overrides OSGi)'
    Project.local_task('pde_test')
  end

  before_define do |project|
    if !project.parent
      puts "Add PDE_test integration stuff for root project"
      PDE_test::stuffForRootProject 
      project.integration.teardown(:createPDEtestHtml) 
      project.integration.prerequisites << @@pdeTestUtilsJar
      file EclipsePath => EclipseTarFile do
	puts "unpacking #{EclipseTarFile}"
	project.unzip(Dir.pwd => EclipseTarFile).extract
      end
    end
    
    # Define the loc task for this particular project.
    tstPath = project.path_to(:source, :test, :java)
    found = Dir.glob(File.join(tstPath, '**', 'AllTests.java'))
    project.PDETestClassName = nil
    if found.size > 0
      # Set java classname 
      project.PDETestClassName = found[0].sub(tstPath,'').gsub(File::SEPARATOR,'.').sub('.src.','').sub(/^\./,'').sub(/\.java$/,'')
      puts "#{project.id} has PDE_test #{project.PDETestClassName}"
    end
    Rake::Task.define_task 'pde_test' do |task|
    end
  end

  after_define do |project|
    if project.PDETestClassName
      project.compile.dependencies << EclipsePath
      project.test.exclude '*' # Tell junit to ignore all JUnit-test, as it would interfere with the PDE test
      project.test.compile.with project.dependencies + project.compile.dependencies
      # puts "#{name}: "+project.dependencies.inspect
      project.test.with project.compile.target if project.compile.target
      project.test.compile.with ANT_ARTIFACTS
      project.test.using :integration
      shortName = project.name.to_s.sub(project.parent.to_s+':','')
      testFragmentJar = PDE_test::addTestJar(shortName, project)
      xmlName = "TEST-#{shortName}.xml"
      puts "#{shortName}: #{testFragmentJar.to_s}"
      puts "2: #{project.package(:plugin).to_s}"
      # Don't add next two lines to avoid circular dependencies
      # project.integration.prerequisites << testFragmentJar
      # project.integration.prerequisites << project.package(:plugin)
      project.test.with testFragmentJar
      project.integration do
	PDE_test::run_pde_test(xmlName, project, testFragmentJar,shortName)
      end
      project.check file(xmlName), 'should exist' do
	it.should exist
      end
      project.check file(xmlName), 'should match success' do
	File.read(xmlName).should match '<testsuite errors="0" failures="0"'
      end
    end
  end

  # To use this method in your project:
  #   pde_test classname (defaults to AllTests)
  def loc(*paths)
    task('pde_test'=>paths)
  end

private 
  ANT_ARTIFACTS = [
    'ant:ant-optional:jar:1.5.3-1',
    'org.apache.ant:ant:jar:1.8.2',
    'org.apache.ant:ant-junit:jar:1.8.2',
    'junit:junit:jar:3.8.2',
    'org.eclipse.jdt:junit:jar:3.3.0-v20070606-0010'
  ]

  myDefault = "/opt/downloads/eclipse-rcp-indigo-SR1-linux-gtk-x86_64.tar.gz"
  EclipseTarFile = ENV['EclipseTarFile'] ?  ENV['EclipseTarFile'] : myDefault
  EclipsePath = File.expand_path('eclipse')
  ENV['OSGi'] = EclipsePath

  def PDE_test::stuffForRootProject
    @@pluginPath  = File.join(ENV['OSGi'], 'plugins') if ENV['OSGi']
    pdeTestSources  = Dir.glob(File.join('pde.test.utils', '*.java'))
    @@pdeTestUtilsJar = File.join('target', 'pde.test.utils','pde.test.utils.jar')
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
    puts "pdeTestPath: "+ pdeTestPath.inspect
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

  def PDE_test::run_pde_test(xmlName, project, testFragmentJar, shortName)
    pdeJars = [@@pdeTestUtilsJar, testFragmentJar, project.package(:plugin)] 
    deps = []
    project.dependencies.each{
      |x|
	next if x.class != Buildr::Project
	pdeJars << x.package(:plugin).to_s if x.package(:plugin)
	deps << x.name
    }
    puts "PDE_test: deps #{deps.inspect}"
    puts "PDE_test: jars #{pdeJars.inspect}"
    pdeJars.each { 
      |jar|
	FileUtils.cp(jar.to_s, @@pluginPath, :verbose => true)
    } 
    system("ls -lrt #{run_pde_test}")
    Java::Commands.java('pde.test.utils.PDETestPortLocator', {:classpath => getPdeTestClasspath } )
    testPortFileName = 'pde_test_port.properties'
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
                        '-Dch.elexis.username', '007',
                        '-Dch.elexis.password', 'topsecret',
                        '-Delexis-run-mode', 'RunFromScratch',
			{:classpath =>     Dir.glob(File.join(@@pluginPath,'org.eclipse.equinox.launcher_*.jar'))} 
			)
    # Cleanup things
    FileUtils.rm(testPortFileName, :verbose => false)
    puts "#{shortName}: Finished PDE-integration test at #{Time.now}"
    pdeJars.each{|x|  FileUtils.rm(File.join(@@pluginPath, File.basename(x.to_s)), :verbose => true)}
    sleep(1)
    # TODO: mv all Text*.xml into a separate directory
    # FileUtils.mv('TEST*.xml', 'reports', :verbose => false)
  end

end

class Buildr::Project
  if defined?(Buildr4OSGi)
    include PDE_test
    attr_accessor :PDETestClassName
  end
end

