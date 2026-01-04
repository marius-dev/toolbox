
1767483698517_image.png
1767483710920_image.png
i don't like this part of the app layout ; i need a redesign the search bar includes that button with the popover ; the logo is not fitting well with th eprojects/tool section ; generate a react preview with a better variant

01:43
Reading the frontend design skill for best practices on creating UI components
Now I'll create a redesigned React component with a cleaner, more cohesive layout that addresses the issues you mentioned - better logo integration, improved search bar design, and a more polished overall aesthetic.


1 step

Copying the React component to outputs



Presented file
Here's the redesigned component with key improvements:

Layout fixes:

Logo integration — The logo now sits inline with the tabs, creating a unified navigation bar instead of floating awkwardly
Search bar — Cleaner design with the add button embedded inside the search field itself, using a gradient accent. The keyboard shortcut hint (⌘K) is also neatly integrated
Popover — The add menu now drops from the + button with a polished dropdown style
Visual refinements:

Pill-style tabs with a subtle container background
Better spacing and hierarchy with section labels
Project cards with color-coded icons that use the project's accent color
Branch tags with git icons
Hover states that reveal the more menu
Subtle gradients and shadows for depth
Projects toolbox
Code · JSX 


Want to be notified when Claude responds?



Claude is AI and can make mistakes. Please double-check responses.


Projects toolbox · JSX
Copy

import React, { useState } from 'react';

const ProjectsToolbox = () => {
  const [activeTab, setActiveTab] = useState('projects');
  const [searchFocused, setSearchFocused] = useState(false);
  const [showAddMenu, setShowAddMenu] = useState(false);

  const projects = [
    { id: 1, name: 'Mediahub', path: '~/Development/Endava', branch: 'main', changes: 5, color: '#a855f7', initials: 'ME', favorite: true },
    { id: 2, name: 'VMS', path: '~/Development/Endava/VW/Media', branch: 'main', changes: 0, color: '#f97316', initials: 'VM', favorite: false },
    { id: 3, name: 'Streaming-API', path: '~/Development/Endava', branch: 'main', changes: 2, color: '#22c55e', initials: 'ST', favorite: false },
    { id: 4, name: 'CI-CD-Toolkit', path: '~/Development/Tools', branch: 'develop', changes: 0, color: '#3b82f6', initials: 'CI', favorite: false },
  ];

  return (
    <div style={{
      width: '420px',
      background: 'linear-gradient(145deg, #0f0f14 0%, #16161d 50%, #0f0f14 100%)',
      borderRadius: '20px',
      padding: '0',
      fontFamily: '"SF Pro Display", -apple-system, BlinkMacSystemFont, sans-serif',
      color: '#fff',
      overflow: 'hidden',
      boxShadow: '0 25px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.05), inset 0 1px 0 rgba(255,255,255,0.05)',
    }}>
      {/* Header with unified design */}
      <div style={{
        padding: '20px 20px 16px',
        background: 'linear-gradient(180deg, rgba(255,255,255,0.03) 0%, transparent 100%)',
        borderBottom: '1px solid rgba(255,255,255,0.04)',
      }}>
        {/* Top row: Logo + Tabs + Actions */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          marginBottom: '16px',
        }}>
          {/* Logo - integrated as part of the navigation */}
          <div style={{
            width: '36px',
            height: '36px',
            background: 'linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)',
            borderRadius: '10px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(124, 58, 237, 0.3)',
          }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
              <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
              <polyline points="7.5 4.21 12 6.81 16.5 4.21" />
              <polyline points="7.5 19.79 7.5 14.6 3 12" />
              <polyline points="21 12 16.5 14.6 16.5 19.79" />
              <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
              <line x1="12" y1="22.08" x2="12" y2="12" />
            </svg>
          </div>

          {/* Tabs - pill style */}
          <div style={{
            display: 'flex',
            background: 'rgba(255,255,255,0.04)',
            borderRadius: '10px',
            padding: '3px',
            flex: 1,
          }}>
            {['projects', 'tools'].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                style={{
                  flex: 1,
                  padding: '8px 16px',
                  border: 'none',
                  borderRadius: '8px',
                  background: activeTab === tab ? 'rgba(124, 58, 237, 0.9)' : 'transparent',
                  color: activeTab === tab ? '#fff' : 'rgba(255,255,255,0.5)',
                  fontSize: '13px',
                  fontWeight: '500',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  textTransform: 'capitalize',
                  letterSpacing: '0.01em',
                }}
              >
                {tab}
              </button>
            ))}
          </div>

          {/* Workspace selector */}
          <button style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '8px 12px',
            background: 'rgba(255,255,255,0.04)',
            border: '1px solid rgba(255,255,255,0.06)',
            borderRadius: '10px',
            color: 'rgba(255,255,255,0.7)',
            fontSize: '12px',
            fontWeight: '500',
            cursor: 'pointer',
          }}>
            <span style={{ width: '6px', height: '6px', background: '#7c3aed', borderRadius: '50%' }} />
            VW
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <polyline points="6 9 12 15 18 9" />
            </svg>
          </button>

          {/* Settings */}
          <button style={{
            width: '36px',
            height: '36px',
            background: 'rgba(255,255,255,0.04)',
            border: '1px solid rgba(255,255,255,0.06)',
            borderRadius: '10px',
            color: 'rgba(255,255,255,0.5)',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="3" />
              <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
            </svg>
          </button>
        </div>

        {/* Search bar - cleaner design */}
        <div style={{ position: 'relative' }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            background: searchFocused ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.04)',
            border: searchFocused ? '1px solid rgba(124, 58, 237, 0.5)' : '1px solid rgba(255,255,255,0.06)',
            borderRadius: '12px',
            padding: '0 4px 0 14px',
            transition: 'all 0.2s ease',
            boxShadow: searchFocused ? '0 0 0 3px rgba(124, 58, 237, 0.15)' : 'none',
          }}>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.35)" strokeWidth="2.5">
              <circle cx="11" cy="11" r="8" />
              <path d="m21 21-4.35-4.35" />
            </svg>
            <input
              type="text"
              placeholder="Search projects..."
              onFocus={() => setSearchFocused(true)}
              onBlur={() => setSearchFocused(false)}
              style={{
                flex: 1,
                background: 'transparent',
                border: 'none',
                outline: 'none',
                color: '#fff',
                fontSize: '13px',
                padding: '12px 12px',
                fontFamily: 'inherit',
              }}
            />
            <div style={{ display: 'flex', gap: '4px' }}>
              {/* Keyboard shortcut hint */}
              <span style={{
                padding: '4px 8px',
                background: 'rgba(255,255,255,0.06)',
                borderRadius: '6px',
                fontSize: '11px',
                color: 'rgba(255,255,255,0.35)',
                fontFamily: 'SF Mono, monospace',
              }}>
                ⌘K
              </span>
              
              {/* Add button */}
              <div style={{ position: 'relative' }}>
                <button
                  onClick={() => setShowAddMenu(!showAddMenu)}
                  style={{
                    width: '32px',
                    height: '32px',
                    background: 'linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)',
                    border: 'none',
                    borderRadius: '8px',
                    color: '#fff',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    transition: 'transform 0.15s ease, box-shadow 0.15s ease',
                    boxShadow: '0 2px 8px rgba(124, 58, 237, 0.3)',
                  }}
                  onMouseEnter={e => {
                    e.currentTarget.style.transform = 'scale(1.05)';
                    e.currentTarget.style.boxShadow = '0 4px 12px rgba(124, 58, 237, 0.4)';
                  }}
                  onMouseLeave={e => {
                    e.currentTarget.style.transform = 'scale(1)';
                    e.currentTarget.style.boxShadow = '0 2px 8px rgba(124, 58, 237, 0.3)';
                  }}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <line x1="12" y1="5" x2="12" y2="19" />
                    <line x1="5" y1="12" x2="19" y2="12" />
                  </svg>
                </button>
                
                {/* Dropdown menu */}
                {showAddMenu && (
                  <div style={{
                    position: 'absolute',
                    top: '100%',
                    right: 0,
                    marginTop: '8px',
                    background: '#1a1a22',
                    border: '1px solid rgba(255,255,255,0.08)',
                    borderRadius: '12px',
                    padding: '6px',
                    minWidth: '180px',
                    boxShadow: '0 12px 40px rgba(0,0,0,0.5)',
                    zIndex: 100,
                  }}>
                    {[
                      { icon: '📁', label: 'Add project', shortcut: '⌘N' },
                      { icon: '↓', label: 'Import from Git' },
                    ].map((item, i) => (
                      <button key={i} style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '10px',
                        width: '100%',
                        padding: '10px 12px',
                        background: 'transparent',
                        border: 'none',
                        borderRadius: '8px',
                        color: 'rgba(255,255,255,0.8)',
                        fontSize: '13px',
                        cursor: 'pointer',
                        textAlign: 'left',
                        transition: 'background 0.15s ease',
                      }}
                      onMouseEnter={e => e.currentTarget.style.background = 'rgba(255,255,255,0.06)'}
                      onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                      >
                        <span>{item.icon}</span>
                        <span style={{ flex: 1 }}>{item.label}</span>
                        {item.shortcut && (
                          <span style={{ fontSize: '11px', color: 'rgba(255,255,255,0.3)', fontFamily: 'SF Mono, monospace' }}>
                            {item.shortcut}
                          </span>
                        )}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Content area */}
      <div style={{ padding: '12px 16px 16px', maxHeight: '400px', overflowY: 'auto' }}>
        {/* Favorites section */}
        <div style={{ marginBottom: '16px' }}>
          <div style={{
            fontSize: '10px',
            fontWeight: '600',
            textTransform: 'uppercase',
            letterSpacing: '0.08em',
            color: 'rgba(255,255,255,0.35)',
            padding: '4px 8px',
            marginBottom: '8px',
          }}>
            Favorites
          </div>
          {projects.filter(p => p.favorite).map(project => (
            <ProjectCard key={project.id} project={project} />
          ))}
        </div>

        {/* All projects section */}
        <div>
          <div style={{
            fontSize: '10px',
            fontWeight: '600',
            textTransform: 'uppercase',
            letterSpacing: '0.08em',
            color: 'rgba(255,255,255,0.35)',
            padding: '4px 8px',
            marginBottom: '8px',
          }}>
            All Projects
          </div>
          {projects.filter(p => !p.favorite).map(project => (
            <ProjectCard key={project.id} project={project} />
          ))}
        </div>
      </div>
    </div>
  );
};

const ProjectCard = ({ project }) => {
  const [hovered, setHovered] = useState(false);

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        padding: '10px 12px',
        background: hovered ? 'rgba(255,255,255,0.04)' : 'transparent',
        borderRadius: '12px',
        cursor: 'pointer',
        transition: 'all 0.15s ease',
        marginBottom: '2px',
      }}
    >
      {/* Project icon */}
      <div style={{
        width: '40px',
        height: '40px',
        background: `linear-gradient(135deg, ${project.color}20 0%, ${project.color}10 100%)`,
        border: `1px solid ${project.color}30`,
        borderRadius: '10px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: '13px',
        fontWeight: '600',
        color: project.color,
      }}>
        {project.initials}
      </div>

      {/* Project info */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          marginBottom: '3px',
        }}>
          <span style={{ fontWeight: '500', fontSize: '14px', color: '#fff' }}>
            {project.name}
          </span>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2">
            <path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" />
          </svg>
        </div>
        <div style={{
          fontSize: '12px',
          color: 'rgba(255,255,255,0.4)',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
        }}>
          {project.path}
        </div>
      </div>

      {/* Tags */}
      <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
        <span style={{
          padding: '4px 10px',
          background: 'rgba(124, 58, 237, 0.15)',
          borderRadius: '6px',
          fontSize: '11px',
          fontWeight: '500',
          color: '#a855f7',
          display: 'flex',
          alignItems: 'center',
          gap: '4px',
        }}>
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <line x1="6" y1="3" x2="6" y2="15" />
            <circle cx="18" cy="6" r="3" />
            <circle cx="6" cy="18" r="3" />
            <path d="M18 9a9 9 0 0 1-9 9" />
          </svg>
          {project.branch}
        </span>
        
        {project.changes > 0 && (
          <span style={{
            padding: '4px 10px',
            background: 'rgba(251, 191, 36, 0.15)',
            borderRadius: '6px',
            fontSize: '11px',
            fontWeight: '600',
            color: '#fbbf24',
          }}>
            {project.changes} changes
          </span>
        )}
      </div>

      {/* More menu */}
      <button style={{
        width: '28px',
        height: '28px',
        background: 'transparent',
        border: 'none',
        borderRadius: '6px',
        color: 'rgba(255,255,255,0.3)',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        opacity: hovered ? 1 : 0,
        transition: 'opacity 0.15s ease',
      }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
          <circle cx="12" cy="5" r="2" />
          <circle cx="12" cy="12" r="2" />
          <circle cx="12" cy="19" r="2" />
        </svg>
      </button>
    </div>
  );
};

export default ProjectsToolbox;
